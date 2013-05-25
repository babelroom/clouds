class HoboMigration93 < ActiveRecord::Migration
  def self.up
    remove_column :skins, :name
  end

  def self.down
    add_column :skins, :name, :string
  end
end
