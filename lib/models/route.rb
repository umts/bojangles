class Route < ActiveRecord::Base
  validates :number, :hastus_id, :avail_id, presence: true, uniqueness: true

  def self.import(records)
    records.each do |data|
      where(data).first_or_create
    end
  end
end
