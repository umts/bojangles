# frozen_string_literal: true

require 'active_record'

class Service < ActiveRecord::Base
  has_many :exceptions, class_name: 'ServiceException'
  has_many :trips

  validates :hastus_id, presence: true, uniqueness: true
  validates :start_date, :end_date, presence: true

  serialize :weekdays, type: Array
  validate :weekdays_format

  def self.added_on(date)
    joins(:exceptions).where(service_exceptions: { date: date,
                                                   exception_type: 'add' })
  end

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

  def self.on(date)
    where('start_date <= ? and end_date >= ?', date, date).select do |service|
      service.weekdays[date.wday]
    end - removed_on(date) + added_on(date)
  end

  def self.removed_on(date)
    joins(:exceptions).where(service_exceptions: { date: date,
                                                   exception_type: 'remove' })
  end

  private

  def weekdays_format
    return if weekdays.length == 7 && weekdays.all? { |d| [true, false].include? d }

    errors.add :weekdays, 'must be a boolean array of length 7'
  end
end
