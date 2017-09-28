class Route < ActiveRecord::Base
  has_many :departures
  validates :number, :avail_id, presence: true, uniqueness: true
end
