class HoboMigration57 < ActiveRecord::Migration
  def self.up
    add_column :conferences, :is_deleted, :boolean
  end

  def self.down
    remove_column :conferences, :is_deleted
  end
end
