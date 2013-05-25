class HoboMigration3 < ActiveRecord::Migration
  def self.up
    create_table :accounts do |t|
      t.string   :name
      t.decimal  :balance, :scale => 2, :precision => 8
      t.decimal  :balance_limit, :scale => 2, :precision => 8
      t.decimal  :max_call_rate, :scale => 2, :precision => 8
      t.integer  :max_users
      t.integer  :max_duration
      t.string   :rec_notification
      t.string   :rec_policy
      t.string   :transcription_options
      t.integer  :rec_min
      t.integer  :rec_max
      t.boolean  :suppress_charges_col
      t.datetime :created_at
      t.datetime :updated_at
    end
  end

  def self.down
    drop_table :accounts
  end
end
