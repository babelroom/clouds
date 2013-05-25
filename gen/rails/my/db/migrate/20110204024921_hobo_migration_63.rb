class HoboMigration63 < ActiveRecord::Migration
  def self.up
    rename_column :email_requests, :key, :link_key
  end

  def self.down
    rename_column :email_requests, :link_key, :key
  end
end
