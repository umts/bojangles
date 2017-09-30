require 'pry-byebug' # TODO: remove

require_relative 'setup/database'

require_relative 'models/departure'
require_relative 'models/route'
require_relative 'models/service'
require_relative 'models/service_exception'
require_relative 'models/stop'
require_relative 'models/trip'

require_relative 'avail/avail'

require_relative 'gtfs/files'
require_relative 'gtfs/data'

module Bojangles

  def prepare
    if GTFS::Files.out_of_date? || ENV['REINITIALIZE']
      GTFS::Files.get_new!
      Stop.import GTFS::Data.stop_records
      Service.import GTFS::Data.calendar_records
      ServiceException.import GTFS::Data.exception_records
      Route.import GTFS::Data.route_records(Avail.route_mappings)
      Trip.import GTFS::Data.trip_records
      Departure.import GTFS::Data.stop_time_records
    end
  end

  def run
    config = JSON.parse File.read('config/config.json')
    Stop.activate config.fetch('stops')

    date = Date.today
    time = Time.now.seconds_since_midnight.to_i / 60
    if Time.now.hour < 4
      date = Date.yesterday
      time += 24 * 60
    end

    # Avail and GTFS departures should be identical data structures
    # with identical data.
    avail_departures = Avail.next_departures_from Stop.active, after: time
    gtfs_departures = Departure.next_from Stop.active, on: date, after: time
    binding.pry
  end
end
