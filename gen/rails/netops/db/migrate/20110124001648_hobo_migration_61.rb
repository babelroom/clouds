class HoboMigration61 < ActiveRecord::Migration
  def self.up
    remove_column :systems, :type
  end

  def self.down
    add_column :systems, :type, :string
  end
end
