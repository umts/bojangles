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
  LOG = File.expand_path('../../log', __FILE__)

  def prepare!
    zip_log_file!
    get_new_files! unless files_up_to_date?
    cache_departures!
  end

  # Returns a hash which you can query by route number and direction,
  # and which stores the headsign of the next departure,
  # the next scheduled departure,
  # and the previous scheduled departure.
  # Example:
  # {['31', '0'] => ['Sunderland', '13:51:00', '14:06:00']}
  def soonest_departures_within(minutes)
    departure_times = {}
    cached_departures.each do |(route_number, direction_id, headsign), times|
      next_time = times.find { |time| time_within? minutes, time }
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

  # Stores departures in the cache file.
  def cache_departures!
    departures = find_departures
    File.open CACHE_FILE, 'w' do |file|
      file.puts departures.to_json
    end
  end

  # Zip yesterday's log file into an archive directory, with filenames indicating the date
  def zip_log_file!
    if File.file? "#{todays_date}.txt"
      # At 4am, so todays_date log file is yesterday's log file
      FileUtils.mkdir_p LOG
      zipfile = File.open "#{todays_date}.txt"
      Zip::Archive.open_buffer zipfile do |archive|
        archive.each do |file|
          file_path = File.join LOG, file.name
          File.open file_path, 'w' do |f|
            f << file.read
          end
        end
      end
    end
  end 

  # Retrieves the cached departures.
  def cached_departures
    departures = JSON.parse(File.read(CACHE_FILE))
    parsed_departures = {}
    departures.each do |route_data, times|
      parsed_departures[JSON.parse(route_data)] = times.map { |time| parse_time time }
    end
    parsed_departures
  end

  # Is the remote GTFS archive more recent than our cached files?
  def files_up_to_date?
    return false unless File.directory? LOCAL_GTFS_DIR
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

  # Find an array of the service IDs which are running today.
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

  # Find the ID of the stop whose name is defined in STOP_NAME
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

  # Returns a hash which is keyed by trip ID,
  # and which stores the trip's route ID, direction, and headsign
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

  # Given the trips operating day and the ID of the stop at STOP_NAME,
  # find the departures at that route.
  # This is a hash keyed by route ID, direction, and headsign,
  # and which stores a sorted array of departure times.
  def find_departures
    filename = [LOCAL_GTFS_DIR, 'stop_times.txt'].join '/'
    stop_id = find_stop_id
    trips = find_trips_operating_today
    # Track the indices so that for each row, we can always include the row after it.
    rows, indices = [], []
    CSV.foreach(filename, headers: true).with_index do |row, index|
      rows << row and next if indices.map(&:succ).include? index # If the previous row has been saved
      trip_id = row.fetch 'trip_id'
      if trips.key? trip_id
        if row.fetch('stop_id') == stop_id
          rows << row
          indices << index
        end
      end
    end
    departures = {}
    # If the departure's trip ID does not match the trip ID of the next row,
    # then it is the last stop in the trip, so it is not a departure.
    # For example, the last stop of an inbound 45 trip will be at Studio Arts Building,
    # but we do *not* want to report a departure with headsign UMass.
    # Basically, trips always end with a headsign change.
    rows.each_slice(2).map do |row, next_row| # Take the first of each pair if it matches
      row if row.fetch('trip_id') == next_row.fetch('trip_id')
    end.compact.each do |row|
      trip_id = row.fetch 'trip_id'
      route_data = trips[trip_id]
      departures[route_data] ||= []
      departures[route_data] << row.fetch('departure_time')
      departures[route_data].sort!
    end
    departures
  end

  # Downloads the ZIP archive
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

  # Parses a string time such as '16:30:00'
  # into a Time object
  def parse_time(time)
    hour, minute = time.split(':').map(&:to_i)
    date = Date.today
    hour -= 24 and date += 1 if hour >= 24
    Time.local date.year, date.month, date.day, hour, minute
  end

  # Checks to see whether a time object falls within n minutes
  def time_within?(minutes, time)
    compare_time = Time.now + (60 * minutes)
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
