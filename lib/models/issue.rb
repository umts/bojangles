# frozen_string_literal: true

require 'active_record'

class Issue < ActiveRecord::Base
  belongs_to :route
  belongs_to :stop

  serialize :alternatives, Array

  validates :headsign, :sdt, presence: true
  validates :issue_type, inclusion: { in: %w[missing incorrect] }

  scope :visible, -> { where visible: true }

  def format_sdt(sdt)
    Time.at(sdt * 60).utc.strftime '%l:%M %P'
  end

  def new?
    github_number.blank?
  end

  def text
    opener = 'This error has recurred.' unless open? && visible?
    body = <<~TEXT
      #{Issue.timestamp}: Route #{route.number} with headsign #{headsign} is #{issue_type}.
      Expected to be departing from #{stop.name} at #{format_sdt(sdt)}.
    TEXT
    if alternatives.present?
      closer = case issue_type
               when 'incorrect'
                 "Saw SDT: #{alternatives.map { |t| format_sdt(t) }.join(', ')}"
               when 'missing'
                 "Found alternatives: #{alternatives.join(', ')}"
               end
    end
    [opener, body, closer].compact.join "\n"
  end

  def title
    "#{stop.name}: #{issue_type} #{route.number} #{headsign} SDT"
  end

  def self.close(issues)
    issues.each do |issue|
      issue = find_by github_number: issue.fetch('number')
      issue.update closed: true if issue.present?
    end
  end

  def self.process_new(issue_data)
    issue_data.map do |data|
      identifiers = data.slice :route, :stop, :headsign, :issue_type
      defaults = data.slice(:sdt, :alternatives).merge(open: true, visible: true)
      create_with(defaults).find_or_create_by(identifiers)
    end
  end

  def self.resolution_message
    "#{timestamp}: This error is no longer visible."
  end

  def self.timestamp
    Time.now.strftime '%l:%M %P'
  end
end
