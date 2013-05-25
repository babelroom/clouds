class HoboMigration84 < ActiveRecord::Migration
  def self.up
    rename_column :conferences, :scheduled, :start
    rename_column :conferences, :actualStart, :actual_start
    rename_column :conferences, :actualEnd, :actual_end
    rename_column :conferences, :statusChanged, :status_changed
  end

  def self.down
    rename_column :conferences, :start, :scheduled
    rename_column :conferences, :actual_start, :actualStart
    rename_column :conferences, :actual_end, :actualEnd
    rename_column :conferences, :status_changed, :statusChanged
  end
end
