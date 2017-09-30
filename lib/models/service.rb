class Service < ActiveRecord::Base
  validates :hastus_id, presence: true, uniqueness: true
  validates :start_date, :end_date, presence: true
  
  has_many :exceptions, class_name: 'ServiceException'

  serialize :weekdays, Array
  validate :weekdays_format

  def dates
    (start_date..end_date).to_a + dates_added - dates_removed
  end

  def dates_added
    exceptions.where(exception_type: 'add').pluck :date
  end

  def dates_removed
    exceptions.where(exception_type: 'remove').pluck :date
  end

  def self.added_on(date)
    joins(:exceptions).where(service_exceptions: { date: date,
                                                   exception_type: 'add' })
  end

  def self.import(records)
    records.each do |data|
      where(data).first_or_create!
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
    unless weekdays.length == 7 && weekdays.all?{ |d| [true, false].include? d }
      errors.add :weekdays, 'must be a boolean array of length 7'
    end
  end
end
