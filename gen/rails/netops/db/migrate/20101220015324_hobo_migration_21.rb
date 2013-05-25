class HoboMigration21 < ActiveRecord::Migration
  def self.up
    add_column :scripts, :startup, :string

    remove_index :pins, :name => :index_pins_on_pins rescue ActiveRecord::StatementInvalid
  end

  def self.down
    remove_column :scripts, :startup

    add_index :pins, [:pin], :unique => true, :name => 'index_pins_on_pins'
  end
end
