class HoboMigration113 < ActiveRecord::Migration
  def self.up
    change_column :pins, :pin, :string, :limit => 6

    change_column :colmodels, :elf, :string, :limit => 10
    change_column :colmodels, :jqgrid_id, :string, :limit => 30

    add_index :pins, [:pin], :unique => true
  end

  def self.down
    change_column :pins, :pin, :string

    change_column :colmodels, :elf, :string
    change_column :colmodels, :jqgrid_id, :string

    remove_index :pins, :name => :index_pins_on_pin rescue ActiveRecord::StatementInvalid
  end
end
