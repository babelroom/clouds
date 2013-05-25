class HoboMigration91 < ActiveRecord::Migration
  def self.up
    drop_table :media_files
  end

  def self.down
    create_table "media_files", :force => true do |t|
      t.string   "name"
      t.string   "attributes"
      t.string   "content_type"
      t.integer  "size"
      t.string   "checksum"
      t.string   "location"
      t.string   "url"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "conference_id"
    end

    add_index "media_files", ["conference_id"], :name => "index_media_files_on_conference_id"
  end
end
