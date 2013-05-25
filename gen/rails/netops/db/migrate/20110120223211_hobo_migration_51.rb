class HoboMigration51 < ActiveRecord::Migration
  def self.up
    add_column :conferences, :is_deleted, :boolean
    add_column :conferences, :deployed_at, :datetime

    add_column :people, :is_deleted, :boolean
    add_column :people, :deployed_at, :datetime
    add_column :people, :fs_server, :string
  end

  def self.down
    remove_column :conferences, :is_deleted
    remove_column :conferences, :deployed_at

    remove_column :people, :is_deleted
    remove_column :people, :deployed_at
    remove_column :people, :fs_server
  end
end
