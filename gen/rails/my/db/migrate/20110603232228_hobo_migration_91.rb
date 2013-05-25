class HoboMigration91 < ActiveRecord::Migration
  def self.up
    create_table :skins do |t|
      t.string   :name
      t.boolean  :public
      t.text     :body
      t.datetime :created_at
      t.datetime :updated_at
    end
  end

  def self.down
    drop_table :skins
  end
end
