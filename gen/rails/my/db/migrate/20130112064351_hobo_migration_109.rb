class HoboMigration109 < ActiveRecord::Migration
  def self.up
    create_table :pins do |t|
      t.datetime :created_at
      t.datetime :updated_at
      t.string   :pin
      t.integer  :user_id
    end
  end

  def self.down
    drop_table :pins
  end
end
