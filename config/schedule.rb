# frozen_string_literal: true

env 'PATH', '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'

job_type :rake, 'cd :path && bundle exec rake :task'

# Every minute after 5am until 3am, check for departure inaccuracies.
# Raw cron asterisk order: minute, hour, day of month, month, day of week
every '* 0-2,5-23 * * *' do
  rake 'bojangles:run'
end

# Every day, check to see if we need new GTFS files.
every :day, at: '4am' do
  rake 'bojangles:prepare'
end
