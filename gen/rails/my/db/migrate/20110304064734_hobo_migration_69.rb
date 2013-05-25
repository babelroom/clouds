class HoboMigration69 < ActiveRecord::Migration
  def self.up
    create_table :media_files do |t|
      t.string   :name
      t.string   :content_type
      t.integer  :size
      t.string   :url
      t.datetime :created_at
      t.datetime :updated_at
      t.integer  :conference_id
      t.integer  :user_id
    end
    add_index :media_files, [:conference_id]
    add_index :media_files, [:user_id]
  end

  def self.down
    drop_table :media_files
  end
end
