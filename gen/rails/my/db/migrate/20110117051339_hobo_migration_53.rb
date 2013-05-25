class HoboMigration53 < ActiveRecord::Migration
  def self.up
    add_column :accounts, :owner_id, :integer

    add_index :accounts, [:owner_id]
  end

  def self.down
    remove_column :accounts, :owner_id

    remove_index :accounts, :name => :index_accounts_on_owner_id rescue ActiveRecord::StatementInvalid
  end
end
