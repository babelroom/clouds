class HoboMigration68 < ActiveRecord::Migration
  def self.up
    rename_column :conferences, :actualEnd, :actual_end
  end

  def self.down
    rename_column :conferences, :actual_end, :actualEnd
  end
end
