class HoboMigration30 < ActiveRecord::Migration
  def self.up
    remove_column :phones, :user_id
    change_column :phones, :acknowledgement, :boolean, :limit => 1, :default => 1

    remove_index :phones, :name => :index_phones_on_user_id rescue ActiveRecord::StatementInvalid
  end

  def self.down
    add_column :phones, :user_id, :integer
    change_column :phones, :acknowledgement, :boolean, :default => true

    add_index :phones, [:user_id]
  end
end
