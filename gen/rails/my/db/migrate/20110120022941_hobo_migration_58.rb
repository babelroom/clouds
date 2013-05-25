class HoboMigration58 < ActiveRecord::Migration
  def self.up
    add_index :users, [:email_address]
  end

  def self.down
    remove_index :users, :name => :index_users_on_email_address rescue ActiveRecord::StatementInvalid
  end
end
