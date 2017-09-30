require 'pry-byebug' # TODO: remove

require_relative 'setup/database'

require_relative 'models/departure'
require_relative 'models/route'
require_relative 'models/service'
require_relative 'models/service_exception'
require_relative 'models/stop'
require_relative 'models/trip'

require_relative 'avail/endpoints'

require_relative 'gtfs/files'
require_relative 'gtfs/data'

module Bojangles
  CONFIG = JSON.parse File.read('config/config.json')

  def prepare
    if GTFS::Files.out_of_date? || ENV['REINITIALIZE']
      GTFS::Files.get_new!
      Stop.import GTFS::Data.stop_records
      Service.import GTFS::Data.calendar_records
      ServiceException.import GTFS::Data.exception_records
      Route.import GTFS::Data.route_records(Avail::Endpoints.route_mappings)
      Trip.import GTFS::Data.trip_records
      Departure.import GTFS::Data.stop_time_records
    end
    Stop.activate CONFIG.fetch('stops')
  end

  def run
    # TODO
  end
end
