class HoboMigration57 < ActiveRecord::Migration
  def self.up
    remove_column :servers, :group
    remove_column :servers, :cluster
    remove_column :servers, :ipv4
  end

  def self.down
    add_column :servers, :group, :string
    add_column :servers, :cluster, :string
    add_column :servers, :ipv4, :string
  end
end
