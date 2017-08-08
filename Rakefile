# frozen_string_literal: true

require_relative 'lib/bojangles'
include Bojangles
require_relative 'lib/gtfs_parser'
include GtfsParser

namespace :bojangles do
  desc 'Compare realtime and GTFS data for discrepancies'
  task :go do
    Bojangles.go!
  end

  desc 'Cache GTFS departure data for the day'
  task :daily do
    # Cache the mapping from route number to Avail route ID
    Bojangles.cache_route_mappings!
    Bojangles.prepare!
  end
end
