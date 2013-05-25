class HoboMigration112 < ActiveRecord::Migration
  def self.up
    add_column :pins, :pin, :string, :length => 6
  end

  def self.down
    remove_column :pins, :pin
  end
end
