# frozen_string_literal: true

require 'active_record'

class Stop < ActiveRecord::Base
  has_many :departures
  has_many :issues

  validates :name, presence: true
  validates :hastus_id, presence: true, uniqueness: true

  scope :active, -> { where active: true }

  def self.activate(names)
    update_all active: false
    names.each do |name|
      find_by!(name: name).update active: true
    end
  end

  def self.import(records)
    records.each do |data|
      puts data[:name]
      record = find_by(data.slice(:hastus_id))
      if record.present?
        record.update! data
      else
        create! data
      end
    end
  end
end
