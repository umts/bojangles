class Stop < ActiveRecord::Base
  has_many :departures
  validates :name, :hastus_id, presence: true, uniqueness: true

  scope :active, -> { where active: true }

  def self.activate(names)
    update_all active: false
    names.each do |name|
      find_by!(name: name).update active: true
    end
  end

  def self.import(records)
    records.each do |data|
      where(data).first_or_create
    end
  end
end
