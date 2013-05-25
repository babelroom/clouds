class HoboMigration25 < ActiveRecord::Migration
  def self.up
    add_column :emails, :owner_id, :integer

    add_index :emails, [:owner_id]
  end

  def self.down
    remove_column :emails, :owner_id

    remove_index :emails, :name => :index_emails_on_owner_id rescue ActiveRecord::StatementInvalid
  end
end
