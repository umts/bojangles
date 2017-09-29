require 'pry-byebug'

require_relative 'setup/database'

require_relative 'models/departure'
require_relative 'models/route'
require_relative 'models/stop'

require_relative 'gtfs/files'
require_relative 'gtfs/data'

module Bojangles
  CONFIG = JSON.parse File.read('config/config.json')
  STOP_NAMES = CONFIG.fetch 'stops'

  def prepare
    GTFS::Files.get_new! unless GTFS::Files.up_to_date?
    Stop.import GTFS::Data.find_stop_records(STOP_NAMES)
    import_stops
    kkjkk
  end

  def run
    # TODO
  end

  private

  def import_stops
    # Any stops removed from the list remain in the database as inactive.
    Stop.update_all active: false
    GTFS::Data.find_stop_records(STOP_NAMES).each do |stop_record|
      stop = Stop.where(stop_record).first_or_create
      stop.update active: true
    end
  end

end
