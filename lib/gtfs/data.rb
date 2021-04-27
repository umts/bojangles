# frozen_string_literal: true

require 'csv'

module GTFS
  module Data
    LOCAL_GTFS_DIR = File.expand_path('../../gtfs_files', __dir__)

    def self.calendar_records
      records = []
      filename = [LOCAL_GTFS_DIR, 'calendar.txt'].join '/'
      CSV.foreach filename, headers: true do |row|
        record = {
          hastus_id: row.fetch('service_id'),
          start_date: Date.parse(row.fetch('start_date')),
          end_date: Date.parse(row.fetch('end_date'))
        }
        weekdays = row.values_at('sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday')
                      .map { |i| i == '1' }
        record[:weekdays] = weekdays
        records << record
      end
      records
    end

    def self.exception_records
      records = []
      filename = [LOCAL_GTFS_DIR, 'calendar_dates.txt'].join '/'
      CSV.foreach filename, headers: true do |row|
        type = case row.fetch('exception_type')
               when '1' then 'add'
               when '2' then 'remove'
               end
        record = {
          service: row.fetch('service_id'),
          date: Date.parse(row.fetch('date')),
          exception_type: type
        }
        records << record
      end
      records
    end

    def self.route_records(route_mappings)
      records = []
      filename = [LOCAL_GTFS_DIR, 'routes.txt'].join '/'
      CSV.foreach filename, headers: true do |row|
        number = row.fetch 'route_short_name'
        next unless route_mappings.key? number

        records << {
          number: number,
          hastus_id: row.fetch('route_id'),
          avail_id: route_mappings[number]
        }
      end
      records
    end

    def self.stop_time_records
      filename = [LOCAL_GTFS_DIR, 'stop_times.txt'].join '/'
      trip_stops = {}
      # Start by finding all the matching trip stops for each trip.
      CSV.foreach filename, headers: true do |row|
        hours, minutes, _seconds = row.fetch('departure_time').split(':').map(&:to_i)
        trip_id = row.fetch('trip_id')
        stop_id = row.fetch('stop_id')
        sdt = hours * 60 + minutes
        trip_stops[trip_id] ||= []
        trip_stops[trip_id] << [stop_id, sdt]
      end
      # Discard the last time in a trip, since this is an arrival,
      # not a departure.
      departures = []
      trip_stops.each_pair do |trip_id, times|
        sorted_times = times.sort_by do |_stop_id, time|
          time
        end
        sorted_times.pop
        sorted_times.each do |stop_id, time|
          departures << { trip_id: trip_id, stop_id: stop_id, sdt: time }
        end
      end
      departures
    end

    def self.stop_records
      records = []
      filename = [LOCAL_GTFS_DIR, 'stops.txt'].join '/'
      CSV.foreach filename, headers: true do |row|
        records << {
          name: row.fetch('stop_name').strip,
          hastus_id: row.fetch('stop_id')
        }
      end
      records
    end

    def self.trip_records
      records = []
      filename = [LOCAL_GTFS_DIR, 'trips.txt'].join '/'
      CSV.foreach filename, headers: true do |row|
        records << {
          route: row.fetch('route_id'),
          service: row.fetch('service_id'),
          hastus_id: row.fetch('trip_id'),
          headsign: row.fetch('trip_headsign')
        }
      end
      records
    end
  end
end
