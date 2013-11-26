class HoboMigration127 < ActiveRecord::Migration
  def self.up
    drop_table :stream_refs
    drop_table :streams

    add_column :media_files, :driver, :string
    add_column :media_files, :driver_params, :text

    remove_index :tokens, :name => :index_email_requests_on_user_id rescue ActiveRecord::StatementInvalid
  end

  def self.down
    remove_column :media_files, :driver
    remove_column :media_files, :driver_params

    create_table "stream_refs", :force => true do |t|
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table "streams", :force => true do |t|
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    add_index :tokens, [:user_id], :name => 'index_email_requests_on_user_id'
  end
end
