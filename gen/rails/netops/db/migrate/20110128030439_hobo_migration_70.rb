class HoboMigration70 < ActiveRecord::Migration
  def self.up
    add_column :calls, :uuid, :string, :limit => 36
    add_column :calls, :dialin, :string
    add_column :calls, :dialout, :string
    add_column :calls, :caller_id, :string
  end

  def self.down
    remove_column :calls, :uuid
    remove_column :calls, :dialin
    remove_column :calls, :dialout
    remove_column :calls, :caller_id
  end
end
