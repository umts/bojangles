# frozen_string_literal: true

require 'octokit'

module GitHub
  class Client
    def initialize(token:, repo: 'umts/realtime-issues')
      @client = Octokit::Client.new access_token: token
      @repo = repo
    end

    def create_or_reopen(issues)
      issues.each do |issue|
        if issue.github_number.blank?
          gh_issue = @client.create_issue @repo,
                                          issue.title,
                                          issue.text,
                                          labels: 'needs triage'
          issue.update github_number: gh_issue[:number]
        elsif !issue.open? || !issue.visible? # don't keep commenting on constant issues
          @client.add_comment @repo,
                              issue.github_number,
                              issue.text
          issue.update visible: true
        end
      end
    end

    def comment_resolved(issues)
      issues.each do |issue|
        @client.add_comment @repo,
                            issue.github_number,
                            Issue.resolution_message
        issue.update visible: false
      end
    end

    def closed_issues
      @client.list_issues @repo, state: 'closed'
    end
  end
end
