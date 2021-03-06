class HoboMigration29 < ActiveRecord::Migration
  def self.up
    add_column :systems, :description, :text

    remove_index :pins, :name => :index_pins_on_pins rescue ActiveRecord::StatementInvalid
  end

  def self.down
    remove_column :systems, :description

    add_index :pins, [:pin], :unique => true, :name => 'index_pins_on_pins'
  end
end
