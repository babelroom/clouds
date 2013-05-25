class HoboMigration5 < ActiveRecord::Migration
  def self.up
    add_column :accounts, :user_id, :integer

    add_column :phones, :user_id, :integer

    add_index :accounts, [:user_id]

    add_index :phones, [:user_id]
  end

  def self.down
    remove_column :accounts, :user_id

    remove_column :phones, :user_id

    remove_index :accounts, :name => :index_accounts_on_user_id rescue ActiveRecord::StatementInvalid

    remove_index :phones, :name => :index_phones_on_user_id rescue ActiveRecord::StatementInvalid
  end
end
