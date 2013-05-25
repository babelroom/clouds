class HoboMigration90 < ActiveRecord::Migration
  def self.up
    rename_column :conferences, :key, :conference_key
  end

  def self.down
    rename_column :conferences, :conference_key, :key
  end
end
