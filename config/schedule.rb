# Every minute, check for departure inaccuracies
every 60.seconds do
  rake 'bojangles:go'
end

# Every day, cache departure data.
every :day, at: '4am' do
  rake 'bojangles:daily'
end
