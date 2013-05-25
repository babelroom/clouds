class HoboMigration56 < ActiveRecord::Migration
  def self.up
    add_column :conferences, :reservationless, :boolean
  end

  def self.down
    remove_column :conferences, :reservationless
  end
end
