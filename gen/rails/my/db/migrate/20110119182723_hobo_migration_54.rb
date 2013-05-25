class HoboMigration54 < ActiveRecord::Migration
  def self.up
    add_column :conferences, :enabled, :boolean
  end

  def self.down
    remove_column :conferences, :enabled
  end
end
