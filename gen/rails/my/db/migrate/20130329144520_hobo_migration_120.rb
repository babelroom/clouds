class HoboMigration120 < ActiveRecord::Migration
  def self.up
    add_column :conferences, :custom_data, :string
  end

  def self.down
    remove_column :conferences, :custom_data
  end
end
