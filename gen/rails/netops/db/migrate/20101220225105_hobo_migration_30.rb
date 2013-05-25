class HoboMigration30 < ActiveRecord::Migration
  def self.up
    create_table :logs do |t|
      t.string   :name
      t.string   :table
      t.integer  :id_in_table
      t.string   :content_type
      t.string   :path
      t.datetime :created_at
      t.datetime :updated_at
    end

    create_table :calls do |t|
      t.datetime :started
      t.datetime :ended
      t.text     :notes
      t.datetime :created_at
      t.datetime :updated_at
    end

    remove_index :pins, :name => :index_pins_on_pins rescue ActiveRecord::StatementInvalid
  end

  def self.down
    drop_table :logs
    drop_table :calls

    add_index :pins, [:pin], :unique => true, :name => 'index_pins_on_pins'
  end
end
