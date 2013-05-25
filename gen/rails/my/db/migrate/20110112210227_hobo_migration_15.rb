class HoboMigration15 < ActiveRecord::Migration
  def self.up
    drop_table :billing_infos
  end

  def self.down
    create_table "billing_infos", :force => true do |t|
      t.string   "title"
      t.string   "legal_name"
      t.string   "attention"
      t.string   "address1"
      t.string   "address2"
      t.string   "city"
      t.string   "state"
      t.string   "zip"
      t.string   "country"
      t.string   "phone"
      t.string   "url"
      t.string   "code"
      t.string   "billing_address1"
      t.string   "billing_address2"
      t.string   "billing_city"
      t.string   "billing_state"
      t.string   "billing_country"
      t.string   "billing_zip"
      t.string   "billing_phone"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "account_id"
    end

    add_index "billing_infos", ["account_id"], :name => "index_billing_infos_on_account_id"
  end
end
