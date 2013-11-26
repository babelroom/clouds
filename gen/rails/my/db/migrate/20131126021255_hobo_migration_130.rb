class HoboMigration130 < ActiveRecord::Migration
  def self.up
    create_table :file_refs do |t|
      t.string   :ref_table
      t.integer  :ref_id
      t.datetime :created_at
      t.datetime :updated_at
      t.integer  :media_file_id
    end
    add_index :file_refs, [:media_file_id]

    remove_index :tokens, :name => :index_email_requests_on_user_id rescue ActiveRecord::StatementInvalid
  end

  def self.down
    drop_table :file_refs

    add_index :tokens, [:user_id], :name => 'index_email_requests_on_user_id'
  end
end
