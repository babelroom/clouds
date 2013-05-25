class HoboMigration59 < ActiveRecord::Migration
  def self.up
    drop_table :servers

    add_column :systems, :type, :string
    add_column :systems, :notes, :text
  end

  def self.down
    remove_column :systems, :type
    remove_column :systems, :notes

    create_table "servers", :force => true do |t|
      t.string   "name"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.text     "notes"
      t.string   "type"
      t.text     "access"
    end
  end
end
