class HoboMigration77 < ActiveRecord::Migration
  def self.up
    add_column :calls, :caller_id, :string
  end

  def self.down
    remove_column :calls, :caller_id
  end
end
