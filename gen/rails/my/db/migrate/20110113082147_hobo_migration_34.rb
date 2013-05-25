class HoboMigration34 < ActiveRecord::Migration
  def self.up
    remove_column :phones, :type
  end

  def self.down
    add_column :phones, :type, :string
  end
end
