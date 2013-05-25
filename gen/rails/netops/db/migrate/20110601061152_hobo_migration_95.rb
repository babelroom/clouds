class HoboMigration95 < ActiveRecord::Migration
  def self.up
    rename_column :systems, :key, :system_key
  end

  def self.down
    rename_column :systems, :system_key, :key
  end
end
