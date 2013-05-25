class HoboMigration46 < ActiveRecord::Migration
  def self.up
    remove_column :servers, :ipv4
  end

  def self.down
    add_column :servers, :ipv4, :integer
  end
end
