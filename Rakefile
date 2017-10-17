# frozen_string_literal: true

require_relative 'lib/bojangles'
include Bojangles

namespace :bojangles do
  desc 'Parse and store GTFS departure data for the day'
  task :prepare do
    Bojangles.prepare
  end

  desc 'Compare Avail realtime feed against GTFS departures'
  task :run do
    Bojangles.run
  end
end
