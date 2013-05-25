class HoboMigration64 < ActiveRecord::Migration
  def self.up
    add_column :conferences, :schedule, :string
  end

  def self.down
    remove_column :conferences, :schedule
  end
end
