class HoboMigration87 < ActiveRecord::Migration
  def self.up
    remove_column :conferences, :status_changed
  end

  def self.down
    add_column :conferences, :status_changed, :datetime
  end
end
