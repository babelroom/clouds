class HoboMigration81 < ActiveRecord::Migration
  def self.up
    drop_table :recordings
  end

  def self.down
    create_table "recordings", :force => true do |t|
      t.datetime "created_at"
      t.datetime "updated_at"
    end
  end
end
