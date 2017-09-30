require 'json'
require 'net/http'

module Avail
  PVTA_BASE_API_URL = 'https://bustracker.pvta.com/InfoPoint/rest'

  # Returns a hash keyed by stop.
  # Each value is a hash mapping from route direction data to the next time.
  # The route direction is data is route and headsign.
  def self.next_departures_from(stops, after:)
    times = {}
    stops.each do |stop|
      uri = departures_uri(stop.hastus_id)
      stop_departure = JSON.parse(Net::HTTP.get(uri)).first
      route_directions = stop_departure.fetch 'RouteDirections'
      route_directions.each do |route_dir|
        route_id = route_dir.fetch('RouteId').to_s
        route = Route.find_by avail_id: route_id
        route_dir.fetch('Departures').each do |departure|
          time = parse_json_unix_timestamp departure.fetch('SDT')
          next if time < after
          trip = departure.fetch 'Trip'
          headsign = trip.fetch 'InternetServiceDesc'
          route_data = [route, headsign]
          times[stop] ||= {}
          existing_time = times[stop][route_data]
          times[stop][route_data] = if existing_time
                                      [existing_time, time].min
                                    else time
                                    end
        end
      end
    end
    times
  end

  def self.route_mappings
    routes_uri = URI([PVTA_BASE_API_URL, 'routes', 'getvisibleroutes'].join '/')
    response = JSON.parse Net::HTTP.get(routes_uri)
    routes = {}
    response.each do |route|
      real_name = route.fetch 'ShortName'
      avail_id = route.fetch 'RouteId'
      routes[real_name] = avail_id
    end
    routes
  end

  private

  def self.departures_uri(stop_id)
    URI([PVTA_BASE_API_URL, 'stopdepartures', 'get', stop_id].join('/'))
  end

  def self.parse_json_unix_timestamp(timestamp)
    match_data = timestamp.match %r{/Date\((\d+)000-0[45]00\)/}
    timestamp = match_data.captures.first.to_i
    Time.at(timestamp).change sec: 0
  end
end
