require 'fileutils'
require 'net/http'
require 'zipruby'

require_relative 'setup/database'

require_relative 'models/departure'
require_relative 'models/route'
require_relative 'models/stop'

module Bojangles
  # CONFIG = JSON.parse File.read('config/config.json')
  LOCAL_GTFS_DIR = File.expand_path('../../gtfs', __FILE__)
  REMOTE_GTFS_PROTOCOL = 'http://'
  REMOTE_GTFS_HOST =     'pvta.com'
  REMOTE_GTFS_PATH =     '/g_trans/google_transit.zip'
  # STOP_NAMES = CONFIG.fetch 'stops'

  def prepare
    get_new_files! unless files_up_to_date?
  end

  def run
    # TODO
  end

  private

  # Is the remote GTFS archive more up-to-date than our cached files?
  def files_up_to_date?
    return false unless File.directory? LOCAL_GTFS_DIR
    http = Net::HTTP.new REMOTE_GTFS_HOST
    begin
      response = http.head REMOTE_GTFS_PATH
    rescue SocketError
      return true
    else
      remote_mtime = DateTime.parse response['last-modified']
      remote_mtime <= File.mtime(LOCAL_GTFS_DIR).to_datetime
    end
  end

  # Downloads the ZIP archive
  def get_new_files!
    FileUtils.rm_rf LOCAL_GTFS_DIR
    FileUtils.mkdir_p LOCAL_GTFS_DIR
    gtfs_url = REMOTE_GTFS_PROTOCOL + REMOTE_GTFS_HOST + REMOTE_GTFS_PATH
    begin
      zipfile = Net::HTTP.get URI(gtfs_url)
    rescue SocketError
      return # TOOO: tell someone something's wrong
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
end
