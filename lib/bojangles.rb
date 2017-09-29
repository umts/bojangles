
require_relative 'setup/database'

require_relative 'models/departure'
require_relative 'models/route'
require_relative 'models/stop'

require_relative 'gtfs'

module Bojangles
  include GTFS

  # CONFIG = JSON.parse File.read('config/config.json')
  # STOP_NAMES = CONFIG.fetch 'stops'

  def prepare
    get_new_files! unless files_up_to_date?
  end

  def run
    # TODO
  end

end
