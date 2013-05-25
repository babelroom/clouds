class HoboMigration99 < ActiveRecord::Migration
  def self.up
    rename_column :webhooks, :headers, :json
  end

  def self.down
    rename_column :webhooks, :json, :headers
  end
end
