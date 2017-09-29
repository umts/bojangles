class Departure < ActiveRecord::Base
  belongs_to :trip
  belongs_to :stop

  validates :sdt, :headsign, presence: true

  delegate :headsign, to: :trip
  delegate :route, to: :trip
end
