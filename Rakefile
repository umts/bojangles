require_relative 'lib/bojangles'
include Bojangles
require_relative 'lib/gtfs_parser'
include GtfsParser

namespace :bojangles do
  task :go do
    Bojangles.go!
  end
  task :daily do
    Bojangles.cache_route_mappings!
    GtfsParser.prepare!
  end
end
