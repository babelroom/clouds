class HoboMigration19 < ActiveRecord::Migration
  def self.up
    create_table :pins do |t|
      t.string   :pins, :limit => 6
      t.string   :use
      t.datetime :created_at
      t.datetime :updated_at
    end
    add_index :pins, [:pins], :unique => true
  end

  def self.down
    drop_table :pins
  end
end
