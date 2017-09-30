class Issue < ActiveRecord::Base
  belongs_to :route
  belongs_to :stop

  validates :headsign, presence: true
  validates :issue_type, inclusion: { in: %w[missing incorrect] }

  def text(sdt, alternatives:)
    case issue_type
    when 'incorrect' then <<~TEXT
      TODO
      TEXT
    when 'missing' then <<~TEXT
      TODO
      TEXT
    end
  end

  def title
    "#{stop.name}: #{issue_type} #{route.number} #{headsign} SDT"
  end
end
