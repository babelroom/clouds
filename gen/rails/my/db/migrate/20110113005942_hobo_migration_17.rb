class HoboMigration17 < ActiveRecord::Migration
  def self.up
    rename_column :emails, :owner_id, :user_id

    remove_index :emails, :name => :index_emails_on_owner_id rescue ActiveRecord::StatementInvalid
    add_index :emails, [:user_id]
  end

  def self.down
    rename_column :emails, :user_id, :owner_id

    remove_index :emails, :name => :index_emails_on_user_id rescue ActiveRecord::StatementInvalid
    add_index :emails, [:owner_id]
  end
end
