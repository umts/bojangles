# frozen_string_literal: true

require 'octokit'

module GitHub
  class Client
    def initialize(token:)
      @client = Octokit::Client.new access_token: token
    end

    def create_or_reopen(issues)
      issues.each do |issue|
        if issue.github_number.blank?
          gh_issue = @client.create_issue 'umts/realtime-issues',
                                          issue.title,
                                          issue.text,
                                          labels: 'needs triage'
          issue.update github_number: gh_issue
        elsif !open? || !visible? # don't keep commenting on constant issues
          @client.add_comment 'umts/realtime-issues',
                              issue.github_number,
                              issue.text
          issue.update visible: true
        end
      end
    end

    def comment_resolved(issues)
      issues.each do |issue|
        @client.add_comment 'umts/realtime-issues',
                            issue.github_number,
                            Issue.resolution_message
      end
    end

    def closed_issues
      @client.list_issues 'umts/realtime-issues', state: 'closed'
    end
  end
end
