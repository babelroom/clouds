class HoboMigration10 < ActiveRecord::Migration
  def self.up
    add_column :conferences, :account_id, :integer

    add_index :conferences, [:account_id]
  end

  def self.down
    remove_column :conferences, :account_id

    remove_index :conferences, :name => :index_conferences_on_account_id rescue ActiveRecord::StatementInvalid
  end
end
