class HoboMigration50 < ActiveRecord::Migration
  def self.up
    add_column :callees, :invitation_id, :integer

    add_index :callees, [:invitation_id]
  end

  def self.down
    remove_column :callees, :invitation_id

    remove_index :callees, :name => :index_callees_on_invitation_id rescue ActiveRecord::StatementInvalid
  end
end
