class HoboMigration36 < ActiveRecord::Migration
  def self.up
    drop_table :choices
  end

  def self.down
    create_table "choices", :force => true do |t|
      t.string   "table_field"
      t.string   "code"
      t.string   "description"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
  end
end
