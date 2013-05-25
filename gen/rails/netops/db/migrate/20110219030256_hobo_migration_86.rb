class HoboMigration86 < ActiveRecord::Migration
  def self.up
    add_column :conferences, :state, :string
  end

  def self.down
    remove_column :conferences, :state
  end
end
