class HoboMigration93 < ActiveRecord::Migration
  def self.up
    remove_column :calls, :dialin
    remove_column :calls, :caller_id
    remove_column :calls, :dialout
  end

  def self.down
    add_column :calls, :dialin, :string
    add_column :calls, :caller_id, :string
    add_column :calls, :dialout, :string
  end
end
