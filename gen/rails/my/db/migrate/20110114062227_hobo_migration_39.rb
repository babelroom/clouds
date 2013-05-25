class HoboMigration39 < ActiveRecord::Migration
  def self.up
    change_column :accounts, :max_users, :integer, :limit => 4, :default => 100
    change_column :accounts, :max_duration, :integer, :limit => 4, :default => 240
  end

  def self.down
    change_column :accounts, :max_users, :integer
    change_column :accounts, :max_duration, :integer
  end
end
