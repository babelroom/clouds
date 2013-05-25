class HoboMigration3 < ActiveRecord::Migration
  def self.up
    create_table :interconnects do |t|
      t.string   :name
      t.text     :description
      t.datetime :created_at
      t.datetime :updated_at
    end
  end

  def self.down
    drop_table :interconnects
  end
end
