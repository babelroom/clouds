class HoboMigration76 < ActiveRecord::Migration
  def self.up
    add_column :media_files, :upload_content_type, :string
    add_column :media_files, :upload_file_size, :integer
  end

  def self.down
    remove_column :media_files, :upload_content_type
    remove_column :media_files, :upload_file_size
  end
end
