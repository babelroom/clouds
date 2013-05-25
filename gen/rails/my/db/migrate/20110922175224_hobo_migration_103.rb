class HoboMigration103 < ActiveRecord::Migration
  def self.up
    remove_column :skins, :public
  end

  def self.down
    add_column :skins, :public, :boolean
  end
end
