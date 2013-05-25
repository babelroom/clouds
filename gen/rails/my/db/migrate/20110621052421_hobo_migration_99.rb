class HoboMigration99 < ActiveRecord::Migration
  def self.up
    add_column :conferences, :introduction, :text
    add_column :conferences, :access_config, :text
  end

  def self.down
    remove_column :conferences, :introduction
    remove_column :conferences, :access_config
  end
end
