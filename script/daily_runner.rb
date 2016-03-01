# Check for most recent GTFS files
# and cache today's departures.
require_relative '../lib/gtfs_parser'
include GtfsParser

GtfsParser.prepare!

# Check the public routes endpoints of the
# realtime feed and cache the route mappings.
require_relative '../lib/bojangles'
include Bojangles

Bojangles.cache_route_mappings!
