class HoboMigration75 < ActiveRecord::Migration
  def self.up
    add_column :media_files, :upload_file_name, :string
  end

  def self.down
    remove_column :media_files, :upload_file_name
  end
end
