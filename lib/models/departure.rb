class Departure < ActiveRecord::Base
  belongs_to :trip
  belongs_to :stop

  validates :sdt, presence: true

  delegate :headsign, to: :trip
  delegate :route, to: :trip

  scope :after, -> (sdt) { where 'sdt >= ?', sdt }
  scope :at, -> (stop) { where stop: stop }
  scope :on, -> (date) { where trip: Trip.on(date) }

  def route_data
    [route, trip.headsign]
  end

  def self.import(records)
    trips = Hash[Trip.pluck(:hastus_id, :id)]
    stops = Hash[Stop.pluck(:hastus_id, :id)]
    records.each do |data|
      sdt = data[:sdt]
      trip = trips[data[:trip_id]]
      stop = stops[data[:stop_id]]
      where(sdt: sdt, trip: trip, stop: stop).first_or_create
    end
  end

  # Returns the next scheduled departure on a date
  # after a time at the given stops.
  # The result is a hash keyed by stops.
  # Each value is a hash mapping from route data to the next departure time.
  # Route data is the combination of a route and a trip headsign.
  def self.next_from(stops, on:, after:)
    times = {}
    departures = on(on).after(after).at(stops)
    stops.each do |stop|
      times[stop] = departures.at(stop).group_by(&:route_data)
      times[stop].each_pair do |route_data, deps|
        times[stop][route_data] = deps.map(&:sdt).min
      end
    end
    times
  end

  def self.on(date)
    where trip: Trip.on(date)
  end
end
