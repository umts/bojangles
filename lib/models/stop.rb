class Stop < ActiveRecord::Base
  has_many :departures
  validates :name, :hastus_id, presence: true, uniqueness: true

  scope :active, -> { where active: true }

  def self.import(records)
    update_all active: false
    records.each do |data|
      where(data).first_or_create.update active: true
    end
  end
end
