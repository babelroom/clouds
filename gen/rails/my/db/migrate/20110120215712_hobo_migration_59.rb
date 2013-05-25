class HoboMigration59 < ActiveRecord::Migration
  def self.up
    add_column :conferences, :deployed_at, :datetime

    add_column :users, :deployed_at, :datetime
  end

  def self.down
    remove_column :conferences, :deployed_at

    remove_column :users, :deployed_at
  end
end
