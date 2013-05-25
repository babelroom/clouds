class HoboMigration60 < ActiveRecord::Migration
  def self.up
    add_column :callees, :started, :datetime
    add_column :callees, :ended, :datetime
    remove_column :callees, :calltime
  end

  def self.down
    remove_column :callees, :started
    remove_column :callees, :ended
    add_column :callees, :calltime, :datetime
  end
end
