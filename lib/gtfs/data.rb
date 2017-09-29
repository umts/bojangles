require 'csv'

module GTFS
  module Data
    LOCAL_GTFS_DIR = File.expand_path('../../../gtfs_files', __FILE__)

    def self.find_stop_records(stop_names)
      stop_records = []
      filename = [LOCAL_GTFS_DIR, 'stops.txt'].join '/'
      CSV.foreach filename, headers: true do |row|
        name = row.fetch('stop_name').strip
        next unless stop_names.include? name
        stop_records << { name: name, hastus_id: row.fetch('stop_id') }
      end
      stop_records
    end
  end
end
