class HoboMigration123 < ActiveRecord::Migration
  def self.up
    add_column :users, :avatar_small, :string
    add_column :users, :avatar_medium, :string
    add_column :users, :avatar_large, :string
  end

  def self.down
    remove_column :users, :avatar_small
    remove_column :users, :avatar_medium
    remove_column :users, :avatar_large
  end
end
