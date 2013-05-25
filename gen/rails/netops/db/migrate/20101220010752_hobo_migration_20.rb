class HoboMigration20 < ActiveRecord::Migration
  def self.up
    rename_column :pins, :pins, :pin

    remove_index :pins, :name => :index_pins_on_pins rescue ActiveRecord::StatementInvalid
    add_index :pins, [:pin], :unique => true
  end

  def self.down
    rename_column :pins, :pin, :pins

    remove_index :pins, :name => :index_pins_on_pin rescue ActiveRecord::StatementInvalid
    add_index :pins, [:pins], :unique => true
  end
end
