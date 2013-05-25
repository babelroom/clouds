class HoboMigration2 < ActiveRecord::Migration
  def self.up
    create_table :conferences do |t|
      t.string   :name
      t.datetime :start
      t.string   :config
      t.datetime :created_at
      t.datetime :updated_at
    end
  end

  def self.down
    drop_table :conferences
  end
end
