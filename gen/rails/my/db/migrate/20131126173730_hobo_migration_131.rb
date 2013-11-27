class HoboMigration131 < ActiveRecord::Migration
  def self.up
    add_column :media_files, :progress, :integer, :default => 10000

    remove_index :tokens, :name => :index_email_requests_on_user_id rescue ActiveRecord::StatementInvalid
  end

  def self.down
    remove_column :media_files, :progress

    add_index :tokens, [:user_id], :name => 'index_email_requests_on_user_id'
  end
end
