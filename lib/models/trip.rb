# frozen_string_literal: true

require 'active_record'

require 'models/route'
require 'models/service'

class Trip < ActiveRecord::Base
  belongs_to :route
  belongs_to :service
  has_many :departures

  validates :hastus_id, presence: true, uniqueness: true
  validates :headsign, presence: true

  def self.import(records)
    records.each do |data|
      data[:route] = Route.find_by hastus_id: data[:route]
      data[:service] = Service.find_by hastus_id: data[:service]
      record = find_by(data.slice(:hastus_id))
      if record.present?
        record.update! data
      else
        create! data
      end
    end
  end

  def self.on(date)
    where service: Service.on(date)
  end
end
