class HoboMigration82 < ActiveRecord::Migration
  def self.up
    create_table :media_files do |t|
      t.string   :name
      t.string   :attributes
      t.string   :content_type
      t.integer  :size
      t.string   :checksum
      t.string   :location
      t.string   :url
      t.datetime :created_at
      t.datetime :updated_at
      t.integer  :conference_id
    end
    add_index :media_files, [:conference_id]
  end

  def self.down
    drop_table :media_files
  end
end
