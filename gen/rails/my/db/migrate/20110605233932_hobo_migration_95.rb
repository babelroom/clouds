class HoboMigration95 < ActiveRecord::Migration
  def self.up
    add_column :skins, :readonly, :boolean, :default => false
  end

  def self.down
    remove_column :skins, :readonly
  end
end
