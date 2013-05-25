class HoboMigration97 < ActiveRecord::Migration
  def self.up
    rename_column :skins, :readonly, :immutable
  end

  def self.down
    rename_column :skins, :immutable, :readonly
  end
end
