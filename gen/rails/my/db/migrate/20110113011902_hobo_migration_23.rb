class HoboMigration23 < ActiveRecord::Migration
  def self.up
    remove_index :emails, :name => :index_emails_on_user_id rescue ActiveRecord::StatementInvalid
  end

  def self.down
    add_index :emails, [:owner_id], :name => 'index_emails_on_user_id'
  end
end
