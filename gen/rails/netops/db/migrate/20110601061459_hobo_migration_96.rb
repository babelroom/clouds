class HoboMigration96 < ActiveRecord::Migration
  def self.up
    rename_column :systems, :system_key, :config_key
  end

  def self.down
    rename_column :systems, :config_key, :system_key
  end
end
