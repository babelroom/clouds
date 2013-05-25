class HoboMigration26 < ActiveRecord::Migration
  def self.up
    change_column :phones, :dial_timeout, :integer, :limit => 4, :default => 45
  end

  def self.down
    change_column :phones, :dial_timeout, :integer
  end
end
