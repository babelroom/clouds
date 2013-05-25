class HoboMigration14 < ActiveRecord::Migration
  def self.up
    add_column :billing_infos, :account_id, :integer

    add_index :billing_infos, [:account_id]
  end

  def self.down
    remove_column :billing_infos, :account_id

    remove_index :billing_infos, :name => :index_billing_infos_on_account_id rescue ActiveRecord::StatementInvalid
  end
end
