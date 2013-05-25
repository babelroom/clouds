class HoboMigration17 < ActiveRecord::Migration
  def self.up
    change_column :pins, :pin, :string, :limit => "6", :null => false

    remove_index :pins, :name => :index_pins_on_pin rescue ActiveRecord::StatementInvalid
  end

  def self.down
    change_column :pins, :pin, :string, :limit => 6, :null => false

    add_index :pins, [:pin]
  end
end
