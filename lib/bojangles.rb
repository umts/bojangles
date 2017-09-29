
require_relative 'setup/database'

require_relative 'models/departure'
require_relative 'models/route'
require_relative 'models/stop'

require_relative 'gtfs/files'

module Bojangles
  # CONFIG = JSON.parse File.read('config/config.json')
  # STOP_NAMES = CONFIG.fetch 'stops'

  def prepare
    GTFS::Files.get_new! unless GTFS::Files.up_to_date?
  end

  def run
    # TODO
  end

end
