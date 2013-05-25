class HoboMigration52 < ActiveRecord::Migration
  def self.up
    remove_column :accounts, :user_id

    remove_index :accounts, :name => :index_accounts_on_user_id rescue ActiveRecord::StatementInvalid
  end

  def self.down
    add_column :accounts, :user_id, :integer

    add_index :accounts, [:user_id]
  end
end
