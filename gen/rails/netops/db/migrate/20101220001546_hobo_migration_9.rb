class HoboMigration9 < ActiveRecord::Migration
  def self.up
    change_column :pins, :pin, :string, :limit => "6", :null => false
    add_index :pins, :pin
  end

  def self.down
    remove_index :pins, :pin
    change_column :pins, :pin, :string
  end
end
