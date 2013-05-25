class HoboMigration42 < ActiveRecord::Migration
  def self.up
    add_column :systems, :access, :string
  end

  def self.down
    remove_column :systems, :access
  end
end
