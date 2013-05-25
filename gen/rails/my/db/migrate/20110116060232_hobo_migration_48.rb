class HoboMigration48 < ActiveRecord::Migration
  def self.up
    drop_table :participants

    remove_column :callees, :participant_id

    remove_index :callees, :name => :index_callees_on_participant_id rescue ActiveRecord::StatementInvalid
  end

  def self.down
    add_column :callees, :participant_id, :integer

    create_table "participants", :force => true do |t|
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "conference_id"
      t.string   "name"
      t.string   "email"
      t.string   "role"
      t.string   "status"
    end

    add_index "participants", ["conference_id"], :name => "index_participants_on_conference_id"

    add_index :callees, [:participant_id]
  end
end
