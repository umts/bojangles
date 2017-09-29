class Departure < ActiveRecord::Base
  belongs_to :route#, through: :trip
  # belongs_to :trip
  belongs_to :stop
  validates :sdt, :headsign, presence: true
end
