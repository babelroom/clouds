class HoboMigration47 < ActiveRecord::Migration
  def self.up
    add_column :servers, :ipv4, :string
  end

  def self.down
    remove_column :servers, :ipv4
  end
end
