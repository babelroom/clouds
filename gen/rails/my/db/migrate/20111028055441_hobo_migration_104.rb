class HoboMigration104 < ActiveRecord::Migration
  def self.up
    add_column :media_files, :multipage_root, :string
  end

  def self.down
    remove_column :media_files, :multipage_root
  end
end
