# frozen_string_literal: true

require_relative 'setup/database'

require_relative 'models/departure'
require_relative 'models/issue'
require_relative 'models/route'
require_relative 'models/service'
require_relative 'models/service_exception'
require_relative 'models/stop'
require_relative 'models/trip'

require_relative 'gtfs/files'
require_relative 'gtfs/data'

require_relative 'avail'
require_relative 'comparator'
require_relative 'github/client'

module Bojangles
  CONFIG = JSON.parse File.read('config/config.json')
  GITHUB_TOKEN = CONFIG.fetch('github_token')
  GITHUB_REPO = CONFIG['github_repo']
  DEPARTURE_FUTURE_MINUTES = 3 * 60

  def prepare
    if GTFS::Files.out_of_date? || ENV['REINITIALIZE']
      GTFS::Files.mark_import_in_progress
      GTFS::Files.get_new!
      Stop.import GTFS::Data.stop_records
      Service.import GTFS::Data.calendar_records
      ServiceException.import GTFS::Data.exception_records
      Route.import GTFS::Data.route_records(Avail.route_mappings)
      Trip.import GTFS::Data.trip_records
      Departure.import GTFS::Data.stop_time_records
      GTFS::Files.mark_import_done
    end
    options = {}.tap do |opts|
      opts[:token] = GITHUB_TOKEN
      opts[:repo] = GITHUB_REPO if GITHUB_REPO
    end
    client = GitHub::Client.new options
    Issue.close client.closed_issues
  end

  def run
    unless GTFS::Files.import_in_progress?
      Stop.activate CONFIG.fetch('stops')

      date = Date.today
      time = Time.now.seconds_since_midnight.to_i / 60
      if Time.now.hour < 4
        date = Date.yesterday
        time += 24 * 60
      end
      time_range = time..(time + DEPARTURE_FUTURE_MINUTES)

      # Avail and GTFS departures should be identical data structures
      # with identical data.
      avail_departures = Avail.next_departures_from Stop.active, after: time
      gtfs_departures = Departure.next_from Stop.active, on: date,
                                                         in_range: time_range

      issue_data = Comparator.compare avail_departures, gtfs_departures
      new_issues = Issue.process_new issue_data
      old_issues = Issue.visible - new_issues
      client = GitHub::Client.new token: GITHUB_TOKEN
      client.create_or_reopen new_issues
      client.comment_resolved old_issues
    end
  end
end
