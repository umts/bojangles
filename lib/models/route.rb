# frozen_string_literal: true

require 'active_record'

class Route < ActiveRecord::Base
  has_many :issues
  has_many :trips

  validates :number, :hastus_id, :avail_id, presence: true, uniqueness: true

  def self.import(records)
    records.each do |data|
      where(data).first_or_create
    end
  end
end
