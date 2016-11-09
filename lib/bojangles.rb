require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/hash/conversions'
require 'digest'
require 'json'
require 'net/http'
require 'pony'
require 'pry-byebug'

require_relative 'departure_comparator'
include DepartureComparator

# Bojangles is the main driver of the script, and is responsible for communicating
# with the Avail realtime feed.
module Bojangles
  if File.file? 'config.json'
    CONFIG = JSON.parse File.read('config.json')
  else raise 'No config file found. Please see the config.json.example file and create a config.json file to match.'
  end

  PVTA_API_URL = 'http://bustracker.pvta.com/InfoPoint/rest'.freeze
  ROUTES_URI = URI([PVTA_API_URL, 'routes', 'getvisibleroutes'].join '/')
  STUDIO_ARTS_BUILDING_ID = 72 # TODO: get from stops.txt instead of writing here
  DEPARTURES_URI = URI([PVTA_API_URL, 'stopdepartures', 'get', STUDIO_ARTS_BUILDING_ID].join '/')

  MAIL_SETTINGS = CONFIG.fetch('mail_settings').symbolize_keys

  CACHED_ROUTES_FILE = 'route_mappings.json'.freeze

  def add_to_sent_messages!(hash)
    hashes = sent_message_hashes + [hash]
    File.open 'message_hashes.json', 'w' do |file|
      file.puts hashes
    end
  end

  # Cache the mapping from avail route ID to route number
  def cache_route_mappings!
    response = JSON.parse(Net::HTTP.get ROUTES_URI)
    routes = {}
    response.each do |route|
      real_name = route.fetch 'ShortName'
      avail_id = route.fetch 'RouteId'
      routes[avail_id] = real_name
    end
    File.open CACHED_ROUTES_FILE, 'w' do |file|
      file.puts routes.to_json
    end
  end

  # Fetch the cached route mappings
  def cached_route_mappings
    JSON.parse File.read(CACHED_ROUTES_FILE)
  end

  # Return the hash mapping route number and headsign to the provided time
  def get_avail_departure_times!
    times = {}
    stop_departure = JSON.parse(Net::HTTP.get DEPARTURES_URI).first
    route_directions = stop_departure.fetch 'RouteDirections'
    route_directions.each do |route|
      route_id = route.fetch('RouteId').to_s
      route_number = cached_route_mappings[route_id]
      departure = route.fetch('Departures').first
      if departure.present?
        departure_time = departure.fetch 'SDT' # scheduled departure time
        trip = departure.fetch 'Trip'
        headsign = trip.fetch 'InternetServiceDesc' # headsign
        times[[route_number, headsign]] = parse_json_unix_timestamp(departure_time)
      end
    end
    times
  end

  def go!
    error_messages, statuses = DepartureComparator.compare

    if error_messages.present?
      message = message_html(error_messages)
      hash = Digest::SHA256.digest message
      unless message_hash_already_sent?(hash)
        start_time = Time.now
        MAIL_SETTINGS[:html_body] = message_html(error_messages)
        if CONFIG['environment'] == 'development'
          MAIL_SETTINGS.merge! via: :smtp, via_options: { address: 'localhost', port: 1025 }
        end
        Pony.mail MAIL_SETTINGS
        update_emailed_status! to: statuses
        add_to_sent_messages! hash
      end
    else 
      end_time = Time.now
      update_log_file! to: { start_time, end_time, error_messages, statuses }
    end
  end

  def message_html(error_messages)
    message = ["This message brought to you by Bojangles, UMass Transit's monitoring service for the PVTA realtime bus departures feed."]
    message << message_list(error_messages)
    message.flatten.join '<br>'
  end

  def message_list(error_messages)
    heading = 'Bojangles has noticed the following errors:'
    list = '<ul>'
    error_messages.each do |error|
      list << '<li>'
      error.split("\n").each do |line|
        list << line
        list << '<br>'
      end
      list << '</li>'
    end
    list << '</ul>'
    [heading, list]
  end

  def message_hash_already_sent?(hash)
    sent_message_hashes.include? hash
  end

  def sent_message_hashes
    if File.file? 'message_hashes.json'
      JSON.parse File.read('message_hashes.json')
    else []
    end
  end

  def parse_json_unix_timestamp(timestamp)
    matches = timestamp.match /\/Date\((\d+)000-0(4|5)00\)\//
    Time.at matches.captures.first.to_i
  end

  def update_emailed_status!(to:)
    File.open 'emailed_status.json', 'w' do |file|
      file.puts to.to_json
    end
  end

  def update_log_file!(to:)
    File.open (File.join log, "#{todays_date}.json"), 'w' do |file|
      file.puts to.to_json
    end
  end
end
