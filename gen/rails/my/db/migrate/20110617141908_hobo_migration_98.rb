class HoboMigration98 < ActiveRecord::Migration
  def self.up
    add_column :invitations, :token, :string, :limit => 40

    add_index :invitations, [:token]
  end

  def self.down
    remove_column :invitations, :token

    remove_index :invitations, :name => :index_invitations_on_token rescue ActiveRecord::StatementInvalid
  end
end
