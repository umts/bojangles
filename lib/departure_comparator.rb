# frozen_string_literal: true

require 'active_support/core_ext/string/strip'

require_relative 'gtfs_parser'
include GtfsParser

# DepartureComparator compares the scheduled departures from the GTFS data and
# the departures obtained from the realtime feed.
module DepartureComparator
  # How many hours in the future can we expect the realtime feed to return
  # departures on a given route?
  DEPARTURE_FUTURE_HOURS = 3

  # Finds the other headsigns leaving from the stop on the route
  # rubocop:disable Style/MultilineBlockChain
  def alternative_headsigns(sign_data, route_number, stop_id)
    sign_data.select do |route, _headsign, stop|
      route == route_number && stop == stop_id
    end.map do |_route, headsign, _stop|
      headsign
    end
  end
  # rubocop:enable Style/MultilineBlockChain

  # Returns an array of messages and by comparing the GTFS
  # scheduled departures to the departures returned by the Avail endpoint
  def compare
    @messages = []
    gtfs_times = soonest_departures_within DEPARTURE_FUTURE_HOURS * 60
    stop_ids = gtfs_times.keys
    begin
      avail_times = Bojangles.get_avail_departure_times!(stop_ids)
    rescue SocketError
      report_feed_down
    end
    stop_ids = cached_stop_ids
    # Look through each scheduled route,
    # and make sure that each route is present,
    # and that the next reported departure has the correct scheduled time.
    gtfs_times.each_pair do |stop_id, gtfs_object|
      stop_name = stop_ids[stop_id]
      gtfs_object.each do	|route_data, (headsign, last_time, next_time)|
        route_number, _direction_id = route_data
        if avail_times.key? [route_number, headsign, stop_id]
          avail_time = avail_times.fetch [route_number, headsign, stop_id]
          # if Avail's returned SDT is before now,
          # check that it's the last scheduled departure from the stop
          # (i.e. the bus is running late).
          if avail_time < Time.now && avail_time != last_time
            report_incorrect_departure route_number, headsign, stop_name,
                                       last_time, avail_time, 'past'
          # if the returned SDT is after now,
          # check that it's the next scheduled departure
          elsif avail_time >= Time.now && avail_time != next_time
            report_incorrect_departure route_number, headsign, stop_name,
                                       next_time, avail_time, 'future'
          end
        else
          other_headsigns = alternative_headsigns(avail_times.keys,
                                                  route_number,
                                                  stop_id)
          report_missing_route route_number, headsign, stop_name, next_time,
                               other_headsigns
        end
      end
    end
    @messages
  end

  # a nicer-looking format of a time.
  def email_format(time)
    time.strftime '%r'
  end

  def report_feed_down
    @messages << <<~message
      The realtime feed is inaccessible via HTTP.
    message
  end

  def report_missing_route(route_number, headsign, stop_name,
                           gtfs_time, other_headsigns)
    message = <<~message
      Route #{route_number} with headsign #{headsign} is missing:
        Expected to be departing from #{stop_name}
        Expected SDT: #{email_format gtfs_time}
    message
    if other_headsigns.length == 1
      message += "  Found alternative: #{other_headsigns.first}"
    elsif other_headsigns.length > 1
      message += "  Found alternatives: #{other_headsigns.join(', ')}"
    end
    @messages << message
  end

  def report_incorrect_departure(route_num, sign, stop_name,
                                 gtfs_time, avail_time, type)
    @messages << <<~message
      Incorrect route #{route_num} SDT at #{stop_name} with headsign #{sign}:
        Saw #{type} departure time, expected to be #{email_format gtfs_time};
        Received SDT #{email_format avail_time}
		message
  end
end
