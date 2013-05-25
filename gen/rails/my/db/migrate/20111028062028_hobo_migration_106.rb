class HoboMigration106 < ActiveRecord::Migration
  def self.up
    change_column :media_files, :multipage, :integer, :limit => 4
  end

  def self.down
    change_column :media_files, :multipage, :string
  end
end
