# frozen_string_literal: true

require 'fileutils'
require 'net/http'
require 'zipruby'
require 'date'

module GTFS
  module Files
    LOCAL_GTFS_DIR = File.expand_path('../../gtfs_files', __dir__)
    IN_PROGRESS_FILE = File.expand_path('../../import_in_progress', __dir__)
    REMOTE_GTFS_PROTOCOL = 'http://'
    REMOTE_GTFS_HOST =     'pvta.com'
    REMOTE_GTFS_PATH =     '/g_trans/google_transit.zip'

    # Downloads the ZIP archive
    # rubocop:disable Naming/AccessorMethodName
    def self.get_new!
      FileUtils.rm_rf LOCAL_GTFS_DIR
      FileUtils.mkdir_p LOCAL_GTFS_DIR
      FileUtils.touch "#{LOCAL_GTFS_DIR}/.keep"
      gtfs_url = REMOTE_GTFS_PROTOCOL + REMOTE_GTFS_HOST + REMOTE_GTFS_PATH
      begin
        zipfile = Net::HTTP.get URI(gtfs_url)
      rescue SocketError
        return # TODO: tell someone something's wrong
      end
      Zip::Archive.open_buffer zipfile do |archive|
        archive.each do |file|
          file_path = File.join LOCAL_GTFS_DIR, file.name
          File.open file_path, 'w' do |f|
            f << file.read
          end
        end
      end
    end
    # rubocop:enable Naming/AccessorMethodName

    def self.import_in_progress?
      File.file? IN_PROGRESS_FILE
    end

    def self.mark_import_in_progress
      FileUtils.touch IN_PROGRESS_FILE
    end

    def self.mark_import_done
      FileUtils.rm IN_PROGRESS_FILE
    end

    # Is the remote GTFS archive more up-to-date than our cached files?
    def self.out_of_date?
      return false unless File.directory? LOCAL_GTFS_DIR
      return true unless File.exist? "#{LOCAL_GTFS_DIR}/agency.txt"

      http = Net::HTTP.new REMOTE_GTFS_HOST
      begin
        response = http.head REMOTE_GTFS_PATH
      rescue SocketError
        false
      else
        remote_mtime = DateTime.parse response['last-modified']
        remote_mtime > File.mtime(LOCAL_GTFS_DIR).to_datetime
      end
    end
  end
end
