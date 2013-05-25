class HoboMigration65 < ActiveRecord::Migration
  def self.up
    remove_column :conferences, :reservationless
  end

  def self.down
    add_column :conferences, :reservationless, :boolean
  end
end
