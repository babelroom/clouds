class HoboMigration82 < ActiveRecord::Migration
  def self.up
    add_column :callees, :meta_data, :text
    add_column :callees, :accounting_code, :string
    add_column :callees, :accounting_desc, :string
    add_column :callees, :notes, :string
    add_column :callees, :account_id, :integer

    add_index :callees, [:account_id]
  end

  def self.down
    remove_column :callees, :meta_data
    remove_column :callees, :accounting_code
    remove_column :callees, :accounting_desc
    remove_column :callees, :notes
    remove_column :callees, :account_id

    remove_index :callees, :name => :index_callees_on_account_id rescue ActiveRecord::StatementInvalid
  end
end
