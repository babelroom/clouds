class HoboMigration37 < ActiveRecord::Migration
  def self.up
    remove_column :pins, :pin

    remove_index :pins, :name => :index_pins_on_pins rescue ActiveRecord::StatementInvalid
    remove_index :pins, :name => :index_pins_on_pin rescue ActiveRecord::StatementInvalid
  end

  def self.down
    add_column :pins, :pin, :string, :limit => 6

    add_index :pins, [:pin], :unique => true, :name => 'index_pins_on_pins'
    add_index :pins, [:pin], :unique => true
  end
end
