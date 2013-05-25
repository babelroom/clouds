class HoboMigration8 < ActiveRecord::Migration
  def self.up
    create_table :pins do |t|
      t.string   :pin
      t.string   :use
      t.datetime :created_at
      t.datetime :updated_at
    end
  end

  def self.down
    drop_table :pins
  end
end
