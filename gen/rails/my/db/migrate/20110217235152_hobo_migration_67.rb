class HoboMigration67 < ActiveRecord::Migration
  def self.up
    rename_column :conferences, :actualStart, :actual_start
  end

  def self.down
    rename_column :conferences, :actual_start, :actualStart
  end
end
