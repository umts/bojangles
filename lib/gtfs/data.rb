require 'csv'

module GTFS
  module Data
    LOCAL_GTFS_DIR = File.expand_path('../../../gtfs_files', __FILE__)

    def self.calendar_records
      calendar_records = []
      filename = [LOCAL_GTFS_DIR, 'calendar.txt'].join '/'
      CSV.foreach filename, headers: true do |row|
        record = {
          hastus_id: row.fetch('service_id'),
          start_date: Date.parse(row.fetch('start_date')),
          end_date: Date.parse(row.fetch('end_date'))
        }
        weekdays = row.values_at(*%w[sunday monday tuesday wednesday thursday friday saturday])
                      .map{ |i| i == '1' }
        record[:weekdays] = weekdays
        calendar_records << record
      end
      calendar_records
    end

    def self.exception_records
      exception_records = []
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
        exception_records << record
      end
      exception_records
    end

    def self.stop_records
      stop_records = []
      filename = [LOCAL_GTFS_DIR, 'stops.txt'].join '/'
      CSV.foreach filename, headers: true do |row|
        stop_records << {
          name: row.fetch('stop_name').strip,
          hastus_id: row.fetch('stop_id')
        }
      end
      stop_records
    end
  end
end
