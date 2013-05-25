class HoboMigration38 < ActiveRecord::Migration
  def self.up
    add_column :pins, :pin, :string, :limit => 6

    add_index :pins, [:pin], :unique => true
  end

  def self.down
    remove_column :pins, :pin

    remove_index :pins, :name => :index_pins_on_pin rescue ActiveRecord::StatementInvalid
  end
end
