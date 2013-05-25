class HoboMigration18 < ActiveRecord::Migration
  def self.up
    drop_table :pins
  end

  def self.down
    create_table "pins", :force => true do |t|
      t.string   "pin",        :limit => 6, :null => false
      t.string   "use"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index "pins", ["pin"], :name => "index_pins_on_pin"
  end
end
