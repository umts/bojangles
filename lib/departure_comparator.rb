require_relative 'gtfs_parser'
include GtfsParser

# DepartureComparator compares the scheduled departures from the GTFS data and
# the departures obtained from the realtime feed.
module DepartureComparator

  @messages = []
  @statuses = {
    feed_down: false,
    missing_routes: [],
    incorrect_times: []
  }

  # How many hours in the future can we expect the realtime feed to return
  # departures on a given route?
  DEPARTURE_FUTURE_HOURS = 3

  def compare
    begin
      avail_times = Bojangles.get_avail_departure_times!
    rescue SocketError
      report_feed_down
    end
    gtfs_times = soonest_departures_within DEPARTURE_FUTURE_HOURS
    # Look through each scheduled route, and make sure that each route is present,
    # and that the next reported departure has the correct scheduled time.
    gtfs_times.each do |route_number, gtfs_time|
      if avail_times.key? route_number
        avail_time = avail_times[route_number]
        if avail_time != gtfs_time
          report_incorrect_departure route_number, gtfs_time, avail_time
        end
      else report_missing_route route_number, gtfs_time
      end
    end
    [@messages, @statuses]
  end

  def report_feed_down
    @messages << <<-message
      The realtime feed is inaccessible via HTTP.
    message
    @statuses[:feed_down] = true
  end

  def report_missing_route(route_number, gtfs_time)
    @messages << <<-message
      Route #{route_number} is missing:
      Expected to be departing from Studio Arts Building
      Expected scheduled departure time #{gtfs_time}
    message
    @statuses[:missing_routes] << route_number
  end

  def report_incorrect_departure(route_number, gtfs_time, avail_time)
    @messages << <<-message
      Incorrect route #{route_number} departure:
      Expected next scheduled departure time #{gtfs_time}
      Received next scheduled departure time #{avail_time}
    message
    @statuses[:incorrect_times] << route_number
  end

end
