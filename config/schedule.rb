every(60.seconds) { script 'runner.rb' }
every(:day, at: '4am'){ script 'daily_runner.rb' }
