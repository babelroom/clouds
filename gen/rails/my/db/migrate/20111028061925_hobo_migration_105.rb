class HoboMigration105 < ActiveRecord::Migration
  def self.up
    rename_column :media_files, :multipage_root, :multipage
  end

  def self.down
    rename_column :media_files, :multipage, :multipage_root
  end
end
