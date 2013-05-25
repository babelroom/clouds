class HoboMigration121 < ActiveRecord::Migration
  def self.up
    rename_table :email_requests, :tokens

    remove_index :tokens, :name => :index_email_requests_on_user_id rescue ActiveRecord::StatementInvalid
    add_index :tokens, [:user_id]
  end

  def self.down
    rename_table :tokens, :email_requests

    remove_index :email_requests, :name => :index_tokens_on_user_id rescue ActiveRecord::StatementInvalid
    add_index :email_requests, [:user_id]
  end
end
