class HoboMigration77 < ActiveRecord::Migration
  def self.up
    add_column :media_files, :upload_updated_at, :datetime
    add_column :media_files, :post_process_status, :string
  end

  def self.down
    remove_column :media_files, :upload_updated_at
    remove_column :media_files, :post_process_status
  end
end
