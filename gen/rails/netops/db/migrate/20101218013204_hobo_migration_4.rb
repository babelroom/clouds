class HoboMigration4 < ActiveRecord::Migration
  def self.up
    add_column :jobs, :script_name, :string
  end

  def self.down
    remove_column :jobs, :script_name
  end
end
