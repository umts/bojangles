class Departure < ActiveRecord::Base
  belongs_to :trip
  belongs_to :stop

  validates :sdt, presence: true

  delegate :headsign, to: :trip
  delegate :route, to: :trip

  def self.import(records)
    records.each do |data|
      trip = Trip.find_by hastus_id: data[:trip_id]
      sdt = data[:sdt]
      stop = Stop.find_by hastus_id: data[:stop_id]
      where(sdt: sdt, trip: trip, stop: stop).first_or_create
    end
  end

  def self.on(date)
    where trip: Trip.on(date)
  end
end
