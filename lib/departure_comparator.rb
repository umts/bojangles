require 'active_support/core_ext/string/strip'

require_relative 'gtfs_parser'
include GtfsParser

# DepartureComparator compares the scheduled departures from the GTFS data and
# the departures obtained from the realtime feed.
module DepartureComparator

  # How many hours in the future can we expect the realtime feed to return
  # departures on a given route?
  DEPARTURE_FUTURE_HOURS = 3

  def compare
    @messages = []
    @statuses = {
      feed_down: false,
      missing_routes: [],
      incorrect_times: []
    }
    begin
      avail_times = Bojangles.get_avail_departure_times!
    rescue SocketError
      report_feed_down
    end
    gtfs_times = soonest_departures_within DEPARTURE_FUTURE_HOURS
    # Look through each scheduled route, and make sure that each route is present,
    # and that the next reported departure has the correct scheduled time.
    gtfs_times.each do |(route_number, headsign), (last_time, next_time)|
      if avail_times.key? [route_number, headsign]
        avail_time = avail_times.fetch [route_number, headsign]
        # if Avail's returned SDT is before now, check that it's the last scheduled
        # departure from the stop (i.e. the bus is running late).
        if avail_time < Time.now && avail_time != last_time
          report_incorrect_departure route_number, headsign, last_time, avail_time, 'past'
        # if the returned SDT is after now, check that it's the next scheduled departure
        elsif avail_time >= Time.now && avail_time != next_time
          report_incorrect_departure route_number, headsign, next_time, avail_time, 'future'
        end
      else report_missing_route route_number, headsign, next_time
      end
    end
    [@messages, @statuses]
  end

  def email_format(time)
    time.strftime '%r'
  end

  def report_feed_down
    @messages << <<-message.strip_heredoc
      The realtime feed is inaccessible via HTTP.
    message
    @statuses[:feed_down] = true
  end

  def report_missing_route(route_number, headsign, gtfs_time)
    @messages << <<-message.strip_heredoc
      Route #{route_number} with headsign #{headsign} is missing:
        Expected to be departing from Studio Arts Building
        Expected scheduled departure time #{email_format gtfs_time}
    message
    @statuses[:missing_routes] << route_number
  end

  def report_incorrect_departure(route_number, headsign, gtfs_time, avail_time, type)
    @messages << <<-message.strip_heredoc
      Incorrect route #{route_number} departure with headsign #{headsign}:
        Saw #{type} departure time, expected to be #{email_format gtfs_time};
        Received #{email_format avail_time}
    message
    @statuses[:incorrect_times] << route_number
  end

end
