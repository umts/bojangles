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
    body = case issue_type
           when 'incorrect' then <<~TEXT
             #{Issue.timestamp}: Route #{route.number} with headsign #{headsign} is missing.
             Expected to be departing from #{stop.name} at #{format_sdt(sdt)}.
             TEXT
           when 'missing' then <<~TEXT
             TODO
             TEXT
           end
    if alternatives.present?
      closer = case issue_type
               when 'incorrect'
                 "Saw SDT: #{alternatives.map{|t| format_sdt(t) }.join(', ')}"
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
      Issue.find_by(number: issue.fetch('number')).update closed: true
    end
  end

  def self.process_new(issue_data)
    issue_data.map do |data|
      issue = where(data.slice :route, :stop, :headsign, :issue_type)
             .first_or_create
      issue.update(data.slice :sdt, :alternatives)
      issue
    end
  end

  def self.resolution_message
    "#{timestamp}: This error is no longer visible."
  end

  private

  def self.timestamp
    Time.now.strftime '%l:%M %P'
  end

end
