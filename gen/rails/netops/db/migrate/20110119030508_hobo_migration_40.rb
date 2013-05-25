class HoboMigration40 < ActiveRecord::Migration
  def self.up
    add_column :conferences, :scheduled, :datetime
    remove_column :conferences, :configuration
  end

  def self.down
    remove_column :conferences, :scheduled
    add_column :conferences, :configuration, :string
  end
end
