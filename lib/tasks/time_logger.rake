namespace :time_logger do
  desc 'Stop all zombie timers'
  task :stop_zombies => :environment do
    TimeLogger.all.each do |time_logger|
      time_logger.stop if time_logger.zombie?
    end
  end
end
