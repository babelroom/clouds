class HoboMigration55 < ActiveRecord::Migration
  def self.up
    remove_column :conferences, :enabled
  end

  def self.down
    add_column :conferences, :enabled, :boolean
  end
end
