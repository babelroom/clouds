class HoboMigration83 < ActiveRecord::Migration
  def self.up
    add_column :callees, :number, :string
  end

  def self.down
    remove_column :callees, :number
  end
end
