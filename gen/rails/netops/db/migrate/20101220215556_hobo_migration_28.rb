class HoboMigration28 < ActiveRecord::Migration
  def self.up
    add_column :people, :system_id, :integer

    add_index :people, [:system_id]

    remove_index :pins, :name => :index_pins_on_pins rescue ActiveRecord::StatementInvalid
  end

  def self.down
    remove_column :people, :system_id

    remove_index :people, :name => :index_people_on_system_id rescue ActiveRecord::StatementInvalid

    add_index :pins, [:pin], :unique => true, :name => 'index_pins_on_pins'
  end
end
