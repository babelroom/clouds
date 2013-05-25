class HoboMigration24 < ActiveRecord::Migration
  def self.up
    remove_column :emails, :owner_id

    remove_index :emails, :name => :index_emails_on_owner_id rescue ActiveRecord::StatementInvalid
    remove_index :emails, :name => :index_emails_on_user_id rescue ActiveRecord::StatementInvalid
  end

  def self.down
    add_column :emails, :owner_id, :integer

    add_index :emails, [:owner_id]
    add_index :emails, [:owner_id], :name => 'index_emails_on_user_id'
  end
end
