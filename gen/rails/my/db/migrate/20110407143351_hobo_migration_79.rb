class HoboMigration79 < ActiveRecord::Migration
  def self.up
    rename_column :media_files, :post_process_status, :slideshow_pages
    change_column :media_files, :slideshow_pages, :integer, :limit => 4
  end

  def self.down
    rename_column :media_files, :slideshow_pages, :post_process_status
    change_column :media_files, :post_process_status, :string
  end
end
