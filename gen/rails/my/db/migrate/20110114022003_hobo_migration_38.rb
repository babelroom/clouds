class HoboMigration38 < ActiveRecord::Migration
  def self.up
    remove_column :users, :first_name
  end

  def self.down
    add_column :users, :first_name, :string
  end
end
