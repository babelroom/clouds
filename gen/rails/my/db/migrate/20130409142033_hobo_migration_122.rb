class HoboMigration122 < ActiveRecord::Migration
  def self.up
    add_column :media_files, :upload_url, :string
  end

  def self.down
    remove_column :media_files, :upload_url
  end
end
