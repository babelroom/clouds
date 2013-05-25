class HoboMigration102 < ActiveRecord::Migration
  def self.up
    add_column :skins, :preview_url, :string
  end

  def self.down
    remove_column :skins, :preview_url
  end
end
