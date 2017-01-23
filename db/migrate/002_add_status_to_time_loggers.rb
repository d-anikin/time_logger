class AddStatusToTimeLoggers < ActiveRecord::Migration
  def change
    add_column :time_loggers, :status_id, :integer
  end
end
