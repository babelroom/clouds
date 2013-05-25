class HoboMigration7 < ActiveRecord::Migration
  def self.up
    add_column :callees, :ringing, :decimal, :scale => 1, :precision => 8
  end

  def self.down
    remove_column :callees, :ringing
  end
end
