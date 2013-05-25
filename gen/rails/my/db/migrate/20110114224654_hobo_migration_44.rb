class HoboMigration44 < ActiveRecord::Migration
  def self.up
    rename_column :conferences, :type, :meeting_type
  end

  def self.down
    rename_column :conferences, :meeting_type, :type
  end
end
