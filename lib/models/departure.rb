class Departure < ActiveRecord::Base
  belongs_to :route
  belongs_to :stop
  validates :sdt, :headsign, presence: true
end
