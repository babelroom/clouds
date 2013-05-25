class HoboMigration79 < ActiveRecord::Migration
  def self.up
    create_table :medias do |t|
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
    add_index :medias, [:conference_id]
  end

  def self.down
    drop_table :medias
  end
end
