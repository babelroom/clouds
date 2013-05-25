class HoboMigration34 < ActiveRecord::Migration
  def self.up
    remove_column :conferences, :origin_system_id

    remove_index :pins, :name => :index_pins_on_pins rescue ActiveRecord::StatementInvalid
  end

  def self.down
    add_column :conferences, :origin_system_id, :string

    add_index :pins, [:pin], :unique => true, :name => 'index_pins_on_pins'
  end
end
