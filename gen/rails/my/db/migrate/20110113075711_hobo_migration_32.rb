class HoboMigration32 < ActiveRecord::Migration
  def self.up
    add_column :phones, :owner_id, :integer

    add_index :phones, [:owner_id]
  end

  def self.down
    remove_column :phones, :owner_id

    remove_index :phones, :name => :index_phones_on_owner_id rescue ActiveRecord::StatementInvalid
  end
end
