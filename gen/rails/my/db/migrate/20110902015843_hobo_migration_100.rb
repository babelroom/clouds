class HoboMigration100 < ActiveRecord::Migration
  def self.up
    add_column :media_files, :bucket, :string
    add_column :media_files, :length, :string
  end

  def self.down
    remove_column :media_files, :bucket
    remove_column :media_files, :length
  end
end
