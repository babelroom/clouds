class HoboMigration39 < ActiveRecord::Migration
  def self.up
    add_column :conferences, :origin_id, :integer
    add_column :conferences, :fs_server, :string
    add_column :conferences, :es_server, :string
  end

  def self.down
    remove_column :conferences, :origin_id
    remove_column :conferences, :fs_server
    remove_column :conferences, :es_server
  end
end
