# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('lib', __dir__)
require 'bojangles'

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
