class HoboMigration81 < ActiveRecord::Migration
  def self.up
    drop_table :medias
  end

  def self.down
    create_table "medias", :force => true do |t|
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

    add_index "medias", ["conference_id"], :name => "index_medias_on_conference_id"
  end
end
