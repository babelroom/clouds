class HoboMigration41 < ActiveRecord::Migration
  def self.up
    add_column :conferences, :origin_ids, :string
    remove_column :conferences, :origin_id
  end

  def self.down
    remove_column :conferences, :origin_ids
    add_column :conferences, :origin_id, :integer
  end
end
