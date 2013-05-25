class HoboMigration74 < ActiveRecord::Migration
  def self.up
    remove_column :media_files, :upload_file_name
  end

  def self.down
    add_column :media_files, :upload_file_name, :string
  end
end
