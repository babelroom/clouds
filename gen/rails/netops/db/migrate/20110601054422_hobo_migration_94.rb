class HoboMigration94 < ActiveRecord::Migration
  def self.up
    add_column :systems, :key, :string
  end

  def self.down
    remove_column :systems, :key
  end
end
