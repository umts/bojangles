class ServiceException < ActiveRecord::Base
  belongs_to :service

  validates :date, presence: true
  validates :exception_type, inclusion: { in: %w[add remove] }

  def self.import(records)
    records.each do |data|
      data[:service] = Service.find_by hastus_id: data[:service]
      where(data).first_or_create!
    end
  end
end
