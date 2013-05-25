class HoboMigration125 < ActiveRecord::Migration
  def self.up
    add_column :users, :origin_data, :string
    add_column :users, :origin_id, :integer

    add_column :conferences, :origin_data, :string
    add_column :conferences, :origin_id, :integer
    remove_column :conferences, :custom_data
  end

  def self.down
    remove_column :users, :origin_data
    remove_column :users, :origin_id

    remove_column :conferences, :origin_data
    remove_column :conferences, :origin_id
    add_column :conferences, :custom_data, :string
  end
end
