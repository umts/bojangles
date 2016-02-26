require 'csv'
require 'json'

GTFS_DIR = File.expand_path('../../gtfs/', __FILE__)
EXAMPLE_STOP_NAME = "Studio Arts Building"
CACHE_FILE = 'cached_departures.json'

module GtfsParser
  def get_files!
    # TODO
  end

  def find_service_ids_today
    filename = [GTFS_DIR, 'calendar_dates.txt'].join '/'
    date = Date.today.strftime '%Y%m%d'
    calendar_dates = []
    CSV.foreach filename, headers: true do |row|
      calendar_dates << row if row.fetch('date') == date
    end
    calendar_dates.map { |row| row.fetch 'service_id' }
                  .select { |name| name.include? 'UMTS' }
  end

  def find_example_stop_id
    filename = [GTFS_DIR, 'stops.txt'].join '/'
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
    filename = [GTFS_DIR, 'trips.txt'].join '/'
    trips = []
    CSV.foreach filename, headers: true do |row|
      trips << row if service_ids.include? row.fetch('service_id')
    end
    trips
  end

  def find_departures
    filename = [GTFS_DIR, 'stop_times.txt'].join '/'
    stop_id = find_example_stop_id
    trips = find_trips_operating_today
    trip_ids = trips.map { |row| row.fetch('trip_id') }
    departures = []
    CSV.foreach filename, headers: true do |row|
      if trip_ids.include? row.fetch('trip_id')
        if row.fetch('stop_id') == stop_id
          departures << row
        end
      end
    end
    departures
  end

  def cache_departures!
    File.open CACHE_FILE, 'w' do |file|
      file.puts find_departures.map(&:to_h).to_json
    end
  end

  def cached_departures
    departures = File.read CACHE_FILE
    JSON.parse departures
  end

  def find_departures_within(minutes)
    cached_departures.select do |row|
      departure_within? minutes, row
    end
  end

  private

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
end
