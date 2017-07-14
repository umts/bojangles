# frozen_string_literal: true
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

  # Returns an array of messages and of statuses by comparing the GTFS
  # scheduled departures to the departures returned by the Avail endpoint
  def compare
    @messages = []
    @statuses = {
      feed_down: false,
      missing_routes: [],
      incorrect_times: []
    }
    gtfs_times = soonest_departures_within DEPARTURE_FUTURE_HOURS * 60
    stop_ids = gtfs_times.keys
    begin
      avail_times = Bojangles.get_avail_departure_times!(stop_ids)
    rescue SocketError
      report_feed_down
    end
    # Look through each scheduled route,
    # and make sure that each route is present,
    # and that the next reported departure has the correct scheduled time.
    gtfs_times.each_pair do |stop_id, gtfs_object|
      gtfs_object.each do	|route_data, (headsign, last_time, next_time)|
        route_number, _direction_id = route_data
        if avail_times.key? [route_number, headsign, stop_id]
          avail_time = avail_times.fetch [route_number, headsign, stop_id]
          # if Avail's returned SDT is before now,
          # check that it's the last scheduled departure from the stop
          # (i.e. the bus is running late).
          if avail_time < Time.now && avail_time != last_time
            report_incorrect_departure route_number, headsign,
                                       last_time, avail_time, 'past'
          # if the returned SDT is after now,
          # check that it's the next scheduled departure
          elsif avail_time >= Time.now && avail_time != next_time
            report_incorrect_departure route_number, headsign,
                                       next_time, avail_time, 'future'
          end
        else report_missing_route route_number, headsign, next_time
        end
      end
    end
    [@messages, @statuses]
  end

  # a nicer-looking format of a time.
  def email_format(time)
    time.strftime '%r'
  end

  def report_feed_down
    @messages << <<~message
      The realtime feed is inaccessible via HTTP.
    message
    @statuses[:feed_down] = true
  end

  def report_missing_route(route_number, headsign, gtfs_time)
    @messages << <<~message
      Route #{route_number} with headsign #{headsign} is missing:
        Expected to be departing from Studio Arts Building
        Expected SDT: #{email_format gtfs_time}
    message
    @statuses[:missing_routes] << route_number
  end

  def report_incorrect_departure(route_num, sign, gtfs_time, avail_time, type)
    @messages << <<~message
      Incorrect route #{route_num} SDT with headsign #{sign}:
        Saw #{type} departure time, expected to be #{email_format gtfs_time};
        Received SDT #{email_format avail_time}
		message
    @statuses[:incorrect_times] << route_num
  end
end
