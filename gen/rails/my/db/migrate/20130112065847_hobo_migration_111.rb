class HoboMigration111 < ActiveRecord::Migration
  def self.up
    remove_column :pins, :pin
  end

  def self.down
    add_column :pins, :pin, :string
  end
end
