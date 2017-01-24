class AddPingAtToTimeLoggers < ActiveRecord::Migration
  def change
    add_column :time_loggers, :ping_at, :datetime
  end
end
