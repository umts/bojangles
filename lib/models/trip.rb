class Trip < ActiveRecord::Base
  belongs_to :route
  belongs_to :service

  validates :hastus_id, :headsign, presence: true, uniqueness: true

  def self.import(records)
    records.each do |data|
      data[:route] = Route.find_by hastus_id: data[:route]
      data[:service] = Service.find_by hastus_id: data[:service]
      where(data).first_or_create
    end
  end
end
