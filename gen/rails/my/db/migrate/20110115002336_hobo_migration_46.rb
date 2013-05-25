class HoboMigration46 < ActiveRecord::Migration
  def self.up
    remove_column :conferences, :endTime
  end

  def self.down
    add_column :conferences, :endTime, :datetime
  end
end
