class HoboMigration47 < ActiveRecord::Migration
  def self.up
    add_column :conferences, :actualStart, :datetime
    add_column :conferences, :actualEnd, :datetime
  end

  def self.down
    remove_column :conferences, :actualStart
    remove_column :conferences, :actualEnd
  end
end
