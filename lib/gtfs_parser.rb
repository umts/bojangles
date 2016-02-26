require 'csv'
require 'json'
require 'pry-byebug'

GTFS_DIR = File.expand_path('../../gtfs/', __FILE__)
EXAMPLE_STOP_NAME = "Studio Arts Building"
CACHE_FILE = 'cached_departures.json'

module GtfsParser

  def cache_departures!
    File.open CACHE_FILE, 'w' do |file|
      file.puts find_departures.map(&:to_h).to_json
    end
  end

  def find_departures_within(minutes)
    cached_departures.select do |row|
      departure_within? minutes, row
    end
  end

  def get_files!
    # TODO
  end

  private

  def find_service_ids_today
    filename = [GTFS_DIR, 'calendar.txt'].join '/'
    entries = []
    weekday_columns = %w(sunday monday tuesday wednesday thursday friday saturday)
    weekday = weekday_columns[Date.today.wday]
    CSV.foreach filename, headers: true do |row|
      service_id = row.fetch('service_id')
      if service_id.include? 'UMTS'
        if row.fetch(weekday) == "1"
          service_id = row.fetch('service_id')
          start_date = Date.parse row.fetch('start_date')
          end_date = Date.parse row.fetch('end_date')
          if (start_date..end_date).include?(Date.today)
            entries << service_id
          end
        end
      end
    end
    entries
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
      if service_ids.include? row.fetch('service_id')
        trips << {id: row.fetch('trip_id'),
                  route_id: row.fetch('route_id')}
      end
    end
    trips
  end

  def find_departures
    filename = [GTFS_DIR, 'stop_times.txt'].join '/'
    stop_id = find_example_stop_id
    trips = find_trips_operating_today
    trip_ids = trips.map { |trip| trip.fetch :id }
    departures = []
    CSV.foreach filename, headers: true do |row|
      trip_id = row.fetch('trip_id')
      if trip_ids.include? trip_id
        if row.fetch('stop_id') == stop_id
          trip = trips.find{ |trip| trip.fetch(:id) == trip_id }
          departures << {route_id: trip.fetch(:route_id),
                         departure_time: row.fetch('departure_time')}
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
end
