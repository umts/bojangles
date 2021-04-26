# frozen_string_literal: true

require 'active_record'

require 'models/trip'
require 'models/stop'

class Departure < ActiveRecord::Base
  FUTURE_HOURS = 3

  belongs_to :trip
  belongs_to :stop

  validates :sdt, presence: true

  delegate :headsign, to: :trip
  delegate :route, to: :trip

  scope :in, ->(range) { where sdt: range }
  scope :at, ->(stop) { where stop: stop }
  scope :on, ->(date) { where trip: Trip.on(date) }

  def route_data
    [route, trip.headsign]
  end

  def self.import(records)
    trips = Trip.pluck(:hastus_id, :id).to_h
    stops = Stop.pluck(:hastus_id, :id).to_h
    records.each do |data|
      data[:trip_id] = trips[data[:trip_id]]
      data[:stop_id] = stops[data[:stop_id].to_i]
      where(data).first_or_create
    end
  end

  # Returns the next scheduled departure on a date
  # after a time at the given stops.
  # The result is a hash keyed by stops.
  # Each value is a hash mapping from route data to the next departure time.
  # Route data is the combination of a route and a trip headsign.
  def self.next_from(stops, on:, in_range:)
    times = {}
    departures = on(on).in(in_range).at(stops)
    stops.each do |stop|
      times[stop] = departures.at(stop).group_by(&:route_data)
      times[stop].each_pair do |route_data, deps|
        times[stop][route_data] = deps.map(&:sdt).min
      end
    end
    times
  end
end
