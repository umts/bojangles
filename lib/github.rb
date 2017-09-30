require 'octokit'

module GitHub
  TOKEN = Bojangles::CONFIG.fetch('github_token')

  @client = Octokit::Client.new access_token: TOKEN

  def self.create_or_reopen(issues)
    issues.each do |issue|
      if issue.github_number.blank?
        gh_issue = @client.create_issue 'umts/realtime_issues',
                                        issue.title,
                                        issue.text,
                                        labels: 'needs triage'
        issue.update github_number: gh_issue
      elsif !open? || !visible? # don't keep commenting on constant issues
        @client.add_comment 'umts/realtime_issues',
                            issue.github_number,
                            issue.text
        issue.update visible: true
      end
    end
  end

  def self.comment_resolved(issues)
    issues.each do |issue|
      @client.add_comment 'umts/realtime-issues',
                          issue.github_number,
                          Issue.resolution_message
    end
  end

  def self.closed_issues
    @client.list_issues 'umts/realtime-issues', state: 'closed'
  end
end
