require 'csv'
require 'fileutils'
require 'json'
require 'net/http'
require 'zipruby'

module GtfsParser
  LOCAL_GTFS_DIR = File.expand_path('../../gtfs/', __FILE__)
  STOP_NAME = 'Studio Arts Building'.freeze
  CACHE_FILE = 'cached_departures.json'.freeze
  GTFS_PROTOCOL = 'http://'.freeze
  GTFS_HOST = 'pvta.com'.freeze
  GTFS_PATH = '/g_trans/google_transit.zip'.freeze

  def prepare!
    get_new_files! unless files_up_to_date?
    cache_departures!
  end

  # Returns two departure times:
  # 1. The departure scheduled to have left most recently (according to the schedule, but not necessarily in reality);
  # 2. The departure scheduled to leave soonest (within 3 hours).
  def soonest_departures_within(hours)
    departure_times = {}
    cached_departures.each do |(route_number, direction_id, headsign), times|
      next_time = times.find { |time| time_within? hours, time }
      if next_time
        last_time = times[times.index(next_time) - 1] unless next_time == times.first
        times_in_same_route_direction = departure_times[[route_number, direction_id]]
        unless times_in_same_route_direction && times_in_same_route_direction.last < next_time
          departure_times[[route_number, direction_id]] = [headsign, last_time, next_time]
        end
      end
    end
    departure_times
  end

  private

  def cache_departures!
    departures = find_departures
    File.open CACHE_FILE, 'w' do |file|
      file.puts departures.to_json
    end
  end

  def cached_departures
    departures = JSON.parse(File.read(CACHE_FILE))
    parsed_departures = {}
    departures.each do |route_data, times|
      parsed_departures[JSON.parse(route_data)] = times.map { |time| parse_time time }
    end
    parsed_departures
  end

  # returns false if the hosted file is more recent
  # than our cached GTFS files
  def files_up_to_date?
    http = Net::HTTP.new GTFS_HOST
    begin
      response = http.head GTFS_PATH
    rescue SocketError
      true
    else
      mtime = DateTime.parse response['last-modified']
      mtime < File.mtime(LOCAL_GTFS_DIR).to_datetime
    end
  end

  def find_service_ids_today
    filename = [LOCAL_GTFS_DIR, 'calendar.txt'].join '/'
    entries = []
    weekday_columns = %w(sunday monday tuesday wednesday thursday friday saturday)
    weekday = weekday_columns[todays_date.wday]
    CSV.foreach filename, headers: true do |row|
      service_id = row.fetch('service_id')
      if service_id.include? 'UMTS'
        if row.fetch(weekday) == '1' # that is to say, if the service type runs today
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

  def find_stop_id
    filename = [LOCAL_GTFS_DIR, 'stops.txt'].join '/'
    stop = {}
    CSV.foreach filename, headers: true do |row|
      if row.fetch('stop_name').include? STOP_NAME
        stop = row
        break
      end
    end
    stop.fetch 'stop_id'
  end

  def find_trips_operating_today
    service_ids = find_service_ids_today
    filename = [LOCAL_GTFS_DIR, 'trips.txt'].join '/'
    trips = {}
    CSV.foreach filename, headers: true do |row|
      if service_ids.include? row.fetch('service_id')
        trips[row.fetch 'trip_id'] = [row.fetch('route_id'),
                                      row.fetch('direction_id'),
                                      row.fetch('trip_headsign')]
      end
    end
    trips
  end

  def find_departures
    filename = [LOCAL_GTFS_DIR, 'stop_times.txt'].join '/'
    stop_id = find_stop_id
    trips = find_trips_operating_today
    departures = {}
    CSV.foreach filename, headers: true do |row|
      trip_id = row.fetch('trip_id')
      if trips.key? trip_id # if the trip is running today
        if row.fetch('stop_id') == stop_id # TODO: screen out last stops in trip
          route_data = trips[trip_id] # route, direction ID, and headsign
          departures[route_data] ||= []
          departures[route_data] << row.fetch('departure_time')
          departures[route_data].sort!
        end
      end
    end
    departures
  end

  def get_new_files!
    FileUtils.rm_rf LOCAL_GTFS_DIR
    FileUtils.mkdir_p LOCAL_GTFS_DIR
    begin
      zipfile = Net::HTTP.get URI(GTFS_PROTOCOL + GTFS_HOST + GTFS_PATH)
    rescue SocketError
      return # TODO: notify that there's some problem
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

  # input e.g. '16:30:00'
  def parse_time(time)
    hour, minute = time.split(':').map(&:to_i)
    date = Date.today
    hour -= 24 and date += 1 if hour >= 24
    Time.local date.year, date.month, date.day, hour, minute
  end

  def time_within?(hours, time)
    compare_time = Time.now + (60 * 60 * hours)
    Time.now < time && time < compare_time
  end

  # Between midnight and 4am, return yesterday.
  def todays_date
    if Time.now.hour < 4
      Date.today - 1
    else Date.today
    end
  end
end
