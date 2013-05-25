class HoboMigration27 < ActiveRecord::Migration
  def self.up
    change_column :phones, :delay, :integer, :limit => 4, :default => 0
    change_column :phones, :acknowledgement, :boolean, :limit => 1, :default => 1
  end

  def self.down
    change_column :phones, :delay, :integer
    change_column :phones, :acknowledgement, :boolean
  end
end
