class HoboMigration43 < ActiveRecord::Migration
  def self.up
    remove_column :systems, :access
  end

  def self.down
    add_column :systems, :access, :string
  end
end
