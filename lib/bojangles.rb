require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/hash/conversions'
require 'json'
require 'net/http'
require 'pony'
require 'pry-byebug'

require_relative 'departure_comparator'
include DepartureComparator

# Bojangles is the main driver of the script, and is responsible for communicating
# with the Avail realtime feed.
module Bojangles
  config_file = File.read 'config.json'
  CONFIG = JSON.parse config_file

  PVTA_API_URL = 'http://bustracker.pvta.com/InfoPoint/rest'.freeze
  ROUTES_URI = URI([PVTA_API_URL, 'routes', 'getvisibleroutes'].join '/')
  STUDIO_ARTS_BUILDING_ID = 72
  DEPARTURES_URI = URI([PVTA_API_URL, 'stopdepartures', 'get', STUDIO_ARTS_BUILDING_ID].join '/')

  MAIL_SETTINGS = CONFIG.fetch('mail_settings').symbolize_keys

  status_file = File.read 'emailed_status.json'
  EMAILED_STATUS = JSON.parse status_file

  CACHED_ROUTES_FILE = 'route_mappings.json'.freeze

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
    routes.count
  end

  def cached_route_mappings
    JSON.parse File.read(CACHED_ROUTES_FILE)
  end

  def get_avail_departure_times!
    times = {}
    stop_departure = JSON.parse(Net::HTTP.get DEPARTURES_URI).first
    route_directions = stop_departure.fetch 'RouteDirections'
    route_directions.each do |route|
      route_id = route.fetch('RouteId').to_s
      route_number = cached_route_mappings[route_id]
      departure = route.fetch('Departures').first
      if departure.present?
        departure_time = departure.fetch 'SDT'
        trip = departure.fetch 'Trip'
        headsign = trip.fetch 'InternetServiceDesc'
        times[[route_number, headsign]] = parse_json_unix_timestamp(departure_time)
      end
    end
    times
  end

  def go!
    error_messages, statuses = DepartureComparator.compare

    if error_messages.present?
      MAIL_SETTINGS[:html_body] = message_html(error_messages)
      if CONFIG['environment'] == 'development'
        MAIL_SETTINGS.merge! via: :smtp, via_options: { address: 'localhost', port: 1025 }
      end
      Pony.mail MAIL_SETTINGS
      update_emailed_status! to: statuses
    end
  end

  def message_html(error_messages)
    message = ["This message brought to you by Bojangles, UMass Transit's monitoring service for the PVTA realtime bus departures feed."]
    message << message_list(error_messages)
    message << 'Bojangles will let you know if anything changes. You can trust Bojangles.'
    message.flatten.join '<br>'
  end

  def message_list(error_messages)
    heading = 'Bojangles has noticed the following errors:'
    list = '<ul>'
    error_messages.each do |error|
      list << '<li>'
      error.split("\n").each do |line|
        list << line.lstrip
        list << '<br>'
      end
      list << '</li>'
    end
    list << '</ul>'
    [heading, list]
  end

  def parse_json_unix_timestamp(timestamp)
    matches = timestamp.match /\/Date\((\d+)000-0500\)\//
    Time.at matches.captures.first.to_i
  end

  def update_emailed_status!(to:)
    File.open 'emailed_status.json', 'w' do |file|
      file.puts to.to_json
    end
  end
end
