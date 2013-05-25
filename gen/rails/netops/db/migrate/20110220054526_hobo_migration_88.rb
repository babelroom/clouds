class HoboMigration88 < ActiveRecord::Migration
  def self.up
    remove_column :conferences, :deployed_at
  end

  def self.down
    add_column :conferences, :deployed_at, :datetime
  end
end
