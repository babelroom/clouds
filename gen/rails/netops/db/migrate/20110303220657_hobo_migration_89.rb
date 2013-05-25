class HoboMigration89 < ActiveRecord::Migration
  def self.up
    add_column :conferences, :key, :string
  end

  def self.down
    remove_column :conferences, :key
  end
end
