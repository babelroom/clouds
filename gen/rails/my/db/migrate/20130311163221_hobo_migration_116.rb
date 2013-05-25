class HoboMigration116 < ActiveRecord::Migration
  def self.up
    create_table :options do |t|
      t.string   :table
      t.integer  :table_id
      t.string   :name
      t.string   :value
      t.datetime :created_at
      t.datetime :updated_at
    end
#    add_index(:options, [:table,:table_id,:name], :unique => true) -- all because hobo/rails sucks
  end

  def self.down
#    remove_index :options, :column => [:table,:table_id,:name]
    drop_table :options
  end
end
