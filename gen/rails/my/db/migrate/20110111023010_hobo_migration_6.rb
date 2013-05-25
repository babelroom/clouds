class HoboMigration6 < ActiveRecord::Migration
  def self.up
    create_table :callees do |t|
      t.datetime :calltime
      t.string   :participant
      t.string   :participant_email
      t.datetime :created_at
      t.datetime :updated_at
      t.integer  :conference_id
      t.integer  :participant_id
    end
    add_index :callees, [:conference_id]
    add_index :callees, [:participant_id]

    create_table :participants do |t|
      t.datetime :created_at
      t.datetime :updated_at
      t.integer  :conference_id
    end
    add_index :participants, [:conference_id]
  end

  def self.down
    drop_table :callees
    drop_table :participants
  end
end
