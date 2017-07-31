# frozen_string_literal: true

require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/hash/conversions'
require 'digest'
require 'json'
require 'net/http'
require 'pony'

require_relative 'departure_comparator'
include DepartureComparator

# Bojangles is the main driver of the script, and is responsible
# for communicating with the Avail realtime feed.
module Bojangles
  raise <<~MESSAGE unless File.file? 'config.json'
    No config file found. Please see the config.json.example file \
    and create a config.json file to match.
  MESSAGE
  CONFIG = JSON.parse File.read('config.json')

  PVTA_BASE_API_URL = 'http://bustracker.pvta.com/InfoPoint/rest'
  ROUTES_URI = URI([PVTA_BASE_API_URL, 'routes', 'getvisibleroutes'].join('/'))

  MAIL_SETTINGS = CONFIG.fetch('mail_settings').symbolize_keys

  CACHED_ROUTES_FILE = 'route_mappings.json'

  # Cache the mapping from avail route ID to route number
  def cache_route_mappings!
    response = JSON.parse(Net::HTTP.get(ROUTES_URI))
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

  def departures_uri(stop_id)
    URI([PVTA_BASE_API_URL, 'stopdepartures', 'get', stop_id].join('/'))
  end

  # Return the hash mapping route number,
  # headsign, and stop_id to the provided time
  def get_avail_departure_times!(stop_ids)
    times = {}
    stop_ids.each do |stop_id|
      departures_endpoint = departures_uri(stop_id)
      stop_departure = JSON.parse(Net::HTTP.get(departures_endpoint)).first
      route_directions = stop_departure.fetch 'RouteDirections'
      route_directions.each do |route|
        route_id = route.fetch('RouteId').to_s
        route_number = cached_route_mappings[route_id]
        departure = route.fetch('Departures').first
        next unless departure.present?
        departure_time = departure.fetch 'SDT' # scheduled departure time
        trip = departure.fetch 'Trip'
        headsign = trip.fetch 'InternetServiceDesc' # headsign
        route_data = [route_number, headsign, stop_id]
        times[route_data] = parse_json_unix_timestamp(departure_time)
      end
    end
    times
  end

  # Cache the error messages
  def cache_error_messages!(current_errors)
    File.open 'error_messages.json', 'w' do |file|
      file.puts current_errors.to_json
    end
  end

  # Fetch the cached error messages
  def cached_error_messages
    if File.file? 'error_messages.json'
      JSON.parse File.read('error_messages.json')
    else []
    end
  end

  # Only the first two lines of an error message need to match for us to decide
  # that we've already sent it.
  def compare_errors(current_errors, old_errors)
    new_errors = current_errors.reject do |error|
      old_errors.any? { |old| error.lines.first(2) == old.lines.first(2) }
    end
    resolved_errors = old_errors.reject do |error|
      current_errors.any? { |new| error.lines.first(2) == new.lines.first(2) }
    end
    [new_errors, resolved_errors]
  end

  # rubocop:disable Style/GuardClause
  def go!
    errors = DepartureComparator.compare
    current_time = Time.now
    new_errors, resolved_errors = compare_errors(errors, cached_error_messages)
    if new_errors.present? || resolved_errors.present?
      MAIL_SETTINGS[:html_body] = message_html(new_errors,
                                               resolved_errors)
      if CONFIG['environment'] == 'development'
        MAIL_SETTINGS[:via] = :smtp
        MAIL_SETTINGS[:via_options] = { address: 'localhost', port: 1025 }
      end
      Pony.mail MAIL_SETTINGS
    end
    cache_error_messages!(errors)
    if new_errors.present?
      update_log_file! to: { current_time: current_time,
                             new_error: new_errors }
    end
  end
  # rubocop:enable Style/GuardClause

  # rubocop:disable Style/IfUnlessModifier
  def message_html(new_errors, resolved_errors)
    message = [<<~MESSAGE.tr("\n", ' ')]
      This message brought to you by Bojangles, UMass Transit's monitoring
      service for the PVTA realtime bus departures feed.
    MESSAGE
    if new_errors.present?
      message << message_list(new_errors, current: true)
    end
    if resolved_errors.present?
      message << message_list(resolved_errors, current: false)
    end
    message.flatten.join '<br>'
  end
  # rubocop:enable Style/IfUnlessModifier

  def message_list(error_messages, current:)
    heading = if current
                'Bojangles has noticed the following errors:'
              else
                'This error has been resolved:'
              end
    list = '<ul>'
    error_messages.each do |error|
      list += '<li>'
      error.split("\n").each do |line|
        list += line
        list += '<br>'
      end
      list += '</li>'
    end
    list += '</ul>'
    [heading, list]
  end

  def parse_json_unix_timestamp(timestamp)
    match_data = timestamp.match %r{/Date\((\d+)000-0[45]00\)/}
    timestamp = match_data.captures.first.to_i
    Time.at(timestamp).change sec: 0
  end

  def prepare!
    stops = CONFIG.fetch 'stops'
    GtfsParser.prepare stops
  end

  def update_log_file!(to:)
    FileUtils.mkdir_p LOG
    File.open File.join(LOG, "#{todays_date}.txt"), 'a' do |file|
      time = '[' + to[:current_time].strftime('%h %d %Y %R') + ']'
      to.delete(:current_time)
      to.keys.each do |error_type|
        to[error_type].each do |error_message|
          file.puts <<~LOG_ENTRY
            #{time} #{error_type.to_s.humanize}: "#{error_message}"
          LOG_ENTRY
        end
      end
    end
  end
end
