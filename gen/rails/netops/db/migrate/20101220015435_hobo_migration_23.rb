class HoboMigration23 < ActiveRecord::Migration
  def self.up
    remove_index :pins, :name => :index_pins_on_pins rescue ActiveRecord::StatementInvalid
  end

  def self.down
    add_index :pins, [:pin], :unique => true, :name => 'index_pins_on_pins'
  end
end
