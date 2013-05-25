class HoboMigration63 < ActiveRecord::Migration
  def self.up
    change_column :systems, :access, :string, :limit => 255
  end

  def self.down
    change_column :systems, :access, :text
  end
end
