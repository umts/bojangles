# frozen_string_literal: true
env :PATH, ENV['PATH']

# Every minute, check for departure inaccuracies
every 5.minutes do
  rake 'bojangles:go'
end

# Every day, cache departure data.
every :day, at: '4am' do
  rake 'bojangles:daily'
end
