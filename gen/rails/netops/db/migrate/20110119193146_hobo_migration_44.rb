class HoboMigration44 < ActiveRecord::Migration
  def self.up
    add_column :systems, :access, :text
  end

  def self.down
    remove_column :systems, :access
  end
end
