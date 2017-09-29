class Service < ActiveRecord::Base
  validates :hastus_id, presence: true, uniqueness: true
  validates :start_date, :end_date, presence: true

  serialize :weekdays, Array
  validate :weekdays_format

  def self.import(records)
    records.each do |data|
      where(data).first_or_create
    end
  end

  def self.on(date)
    where('start_date <= ? and end_date >= ?', date, date).select do |service|
      service.weekdays[date.wday]
    end
  end

  private

  def weekdays_format
    unless weekdays.length == 7 && weekdays.all?{ |d| [true, false].include? d }
      errors.add :weekdays, 'must be a boolean array of length 7'
    end
  end
end
