class HoboMigration35 < ActiveRecord::Migration
  def self.up
    create_table :choices do |t|
      t.string   :table_field
      t.string   :code
      t.string   :description
      t.datetime :created_at
      t.datetime :updated_at
    end
  end

  def self.down
    drop_table :choices
  end
end
