class Stop < ActiveRecord::Base
  has_many :departures
  validates :name, :hastus_id, presence: true, uniqueness: true
end
