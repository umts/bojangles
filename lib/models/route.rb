# frozen_string_literal: true

require 'active_record'

class Route < ActiveRecord::Base
  has_many :issues
  has_many :trips

  validates :number, :hastus_id, :avail_id, presence: true, uniqueness: true

  def self.import(records)
    records.each do |data|
      record = find_by(data.slice(:hastus_id))
      if record.present?
        record.update! data
      else
        create! data
      end
    end
  end
end
