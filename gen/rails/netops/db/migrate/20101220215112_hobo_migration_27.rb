class HoboMigration27 < ActiveRecord::Migration
  def self.up
    create_table :conferences do |t|
      t.string   :origin_system_id
      t.string   :name
      t.string   :configuration
      t.datetime :created_at
      t.datetime :updated_at
      t.integer  :system_id
    end
    add_index :conferences, [:system_id]

    create_table :systems do |t|
      t.string   :name
      t.string   :configuration
      t.datetime :created_at
      t.datetime :updated_at
    end

    create_table :people do |t|
      t.string   :origin_system_id
      t.string   :name
      t.string   :dialout
      t.string   :email
      t.string   :pin
      t.string   :dialin
      t.string   :configuration
      t.datetime :created_at
      t.datetime :updated_at
      t.integer  :conference_id
    end
    add_index :people, [:conference_id]

    remove_index :pins, :name => :index_pins_on_pins rescue ActiveRecord::StatementInvalid
  end

  def self.down
    drop_table :conferences
    drop_table :systems
    drop_table :people

    add_index :pins, [:pin], :unique => true, :name => 'index_pins_on_pins'
  end
end
