class HoboMigration33 < ActiveRecord::Migration
  def self.up
    add_column :scripts, :script_format_id, :integer

    add_index :scripts, [:script_format_id]

    remove_index :pins, :name => :index_pins_on_pins rescue ActiveRecord::StatementInvalid
  end

  def self.down
    remove_column :scripts, :script_format_id

    remove_index :scripts, :name => :index_scripts_on_script_format_id rescue ActiveRecord::StatementInvalid

    add_index :pins, [:pin], :unique => true, :name => 'index_pins_on_pins'
  end
end
