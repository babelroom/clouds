class HoboMigration52 < ActiveRecord::Migration
  def self.up
    remove_column :conferences, :es_server

    remove_column :people, :origin_system_id
  end

  def self.down
    add_column :conferences, :es_server, :string

    add_column :people, :origin_system_id, :string
  end
end
