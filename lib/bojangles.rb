require 'pry-byebug'

require_relative 'setup/database'

require_relative 'models/departure'
require_relative 'models/route'
require_relative 'models/stop'

require_relative 'gtfs/files'
require_relative 'gtfs/data'

module Bojangles
  CONFIG = JSON.parse File.read('config/config.json')

  def prepare
    unless GTFS::Files.up_to_date?
      GTFS::Files.get_new!
      Stop.import GTFS::Data.stop_records
    end
    Stop.activate CONFIG.fetch('stops')
  end

  def run
    # TODO
  end
end
