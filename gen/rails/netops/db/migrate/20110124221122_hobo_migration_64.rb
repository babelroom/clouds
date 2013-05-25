class HoboMigration64 < ActiveRecord::Migration
  def self.up
    remove_column :pins, :use
  end

  def self.down
    add_column :pins, :use, :string
  end
end
