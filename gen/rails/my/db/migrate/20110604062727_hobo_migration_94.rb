class HoboMigration94 < ActiveRecord::Migration
  def self.up
    add_column :skins, :name, :string
  end

  def self.down
    remove_column :skins, :name
  end
end
