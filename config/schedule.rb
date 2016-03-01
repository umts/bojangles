every 60.seconds do
  rake 'bojangles:go'
end
every :day, at: '4am' do
  rake 'bojangles:daily'
end
