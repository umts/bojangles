require 'csv'
require 'json'
require 'net/http'
require 'pry-byebug'
require 'zipruby'

module GtfsParser
  LOCAL_GTFS_DIR = File.expand_path('../../gtfs/', __FILE__)
  EXAMPLE_STOP_NAME = 'Studio Arts Building'.freeze
  CACHE_FILE = 'cached_departures.json'
  GTFS_HOST = 'http://pvta.com'
  GTFS_PATH = '/g_trans/google_transit.zip'

  def cache_departures!
    File.open CACHE_FILE, 'w' do |file|
      file.puts find_departures.map(&:to_h).to_json
    end
  end

  def departures_within(minutes)
    cached_departures.select do |row|
      departure_within? minutes, row
    end
  end

  def get_files!
    FileUtils.rm_rf LOCAL_GTFS_DIR
    FileUtils.mkdir_p LOCAL_GTFS_DIR
    zipfile = Net::HTTP.get URI(GTFS_HOST + GTFS_PATH)
    Zip::Archive.open_buffer(zipfile) do |archive|
      archive.each do |file|
        file_path = File.join(LOCAL_GTFS_DIR, file.name)
        File.open(file_path, 'w') do |f|
          f << file.read
        end
      end
    end
  end

  def prepare!
    get_files! && cache_departures! unless files_valid?
    cache_departures! unless cache_valid?
  end

  private

  # returns false if the hosted file is more recent
  # than our cached departures
  def files_valid?
    http = Net::HTTP.new GTFS_HOST
    response = http.head GTFS_PATH
    mtime = DateTime.parse response['last-modified']
    mtime < File.mtime(CACHE_FILE)
  end

  def find_service_ids_today
    filename = [LOCAL_GTFS_DIR, 'calendar.txt'].join '/'
    entries = []
    weekday_columns = %w(sunday monday tuesday wednesday thursday friday saturday)
    weekday = weekday_columns[Date.today.wday]
    CSV.foreach filename, headers: true do |row|
      service_id = row.fetch('service_id')
      if service_id.include? 'UMTS'
        if row.fetch(weekday) == '1'
          service_id = row.fetch('service_id')
          start_date = Date.parse row.fetch('start_date')
          end_date = Date.parse row.fetch('end_date')
          if (start_date..end_date).cover?(Date.today)
            entries << service_id
          end
        end
      end
    end
    entries
  end

  def find_example_stop_id
    filename = [LOCAL_GTFS_DIR, 'stops.txt'].join '/'
    stop = {}
    CSV.foreach filename, headers: true do |row|
      if row.fetch('stop_name').include? EXAMPLE_STOP_NAME
        stop = row
        break
      end
    end
    stop.fetch 'stop_id'
  end

  def find_trips_operating_today
    service_ids = find_service_ids_today
    filename = [LOCAL_GTFS_DIR, 'trips.txt'].join '/'
    trips = []
    CSV.foreach filename, headers: true do |row|
      if service_ids.include? row.fetch('service_id')
        trips << { id: row.fetch('trip_id'),
                   route_id: row.fetch('route_id') }
      end
    end
    trips
  end

  def find_departures
    filename = [LOCAL_GTFS_DIR, 'stop_times.txt'].join '/'
    stop_id = find_example_stop_id
    trips = find_trips_operating_today
    trip_ids = trips.map { |trip| trip.fetch :id }
    departures = []
    CSV.foreach filename, headers: true do |row|
      trip_id = row.fetch('trip_id')
      if trip_ids.include? trip_id
        if row.fetch('stop_id') == stop_id
          trip = trips.find { |trip_row| trip_row.fetch(:id) == trip_id }
          departures << { route_id: trip.fetch(:route_id),
                          departure_time: row.fetch('departure_time') }
        end
      end
    end
    departures
  end

  def cached_departures
    JSON.parse File.read(CACHE_FILE)
  end

  # input e.g. '16:30:00'
  def parse_departure_time(time)
    hour, minute = time.split(':').map(&:to_i)
    date = Date.today
    hour -= 24 and date += 1 if hour >= 24
    Time.local date.year, date.month, date.day, hour, minute
  end

  def departure_within?(minutes, row)
    compare_time = Time.now + (60 * minutes)
    time = parse_departure_time row.fetch('departure_time')
    Time.now < time && time < compare_time
  end

  def cache_valid?
    yesterday = Time.now - (24 * 60 * 60)
    # re-cache if it's 24 hours old
    File.exists?(CACHE_FILE) && File.mtime(CACHE_FILE) > yesterday
  end
end
