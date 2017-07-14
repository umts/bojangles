# frozen_string_literal: true
require_relative 'lib/bojangles'
include Bojangles
require_relative 'lib/gtfs_parser'
include GtfsParser

namespace :bojangles do
  task :go do
    Bojangles.go!
  end
  task :daily do
    # Cache the mapping from route number to Avail route ID
    Bojangles.cache_route_mappings!
    Bojangles.prepare!
  end
end
