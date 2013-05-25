class HoboMigration58 < ActiveRecord::Migration
  def self.up
    add_column :servers, :type, :string
    add_column :servers, :access, :text
  end

  def self.down
    remove_column :servers, :type
    remove_column :servers, :access
  end
end
