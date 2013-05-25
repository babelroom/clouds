class HoboMigration4 < ActiveRecord::Migration
  def self.up
    create_table :phones do |t|
      t.string   :identifier
      t.string   :type
      t.string   :dial_options
      t.string   :call_options
      t.string   :sms_carrier
      t.string   :sms_identifier
      t.string   :extension
      t.integer  :delay
      t.integer  :dial_timeout
      t.boolean  :acknowledgement
      t.datetime :created_at
      t.datetime :updated_at
    end
  end

  def self.down
    drop_table :phones
  end
end
