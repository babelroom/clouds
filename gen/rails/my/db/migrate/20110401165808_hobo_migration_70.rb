class HoboMigration70 < ActiveRecord::Migration
  def self.up
    add_column :conferences, :uri, :string

    add_column :users, :phone, :string
    add_column :users, :image, :string
  end

  def self.down
    remove_column :conferences, :uri

    remove_column :users, :phone
    remove_column :users, :image
  end
end
