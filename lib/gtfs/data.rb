require 'csv'

module GTFS
  module Data
    LOCAL_GTFS_DIR = File.expand_path('../../../gtfs_files', __FILE__)

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
