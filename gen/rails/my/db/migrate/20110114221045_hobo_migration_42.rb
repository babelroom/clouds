class HoboMigration42 < ActiveRecord::Migration
  def self.up
    remove_column :conferences, :transcirption_access
  end

  def self.down
    add_column :conferences, :transcirption_access, :string
  end
end
