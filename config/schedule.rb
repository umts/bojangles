# frozen_string_literal: true
env :PATH, ENV['PATH']

# Every minute after 5am, check for departure inaccuracies
# raw cron asterisk order: minute, hour, day of month, month, day of week
every '* 0-2,5-23 * * *' do
  rake 'bojangles:go'
end

# Every day, cache departure data.
every :day, at: '4am' do
  rake 'bojangles:daily'
end
