class HoboMigration28 < ActiveRecord::Migration
  def self.up
    change_column :phones, :acknowledgement, :boolean, :limit => 1, :default => 1
  end

  def self.down
    change_column :phones, :acknowledgement, :boolean, :default => true
  end
end
