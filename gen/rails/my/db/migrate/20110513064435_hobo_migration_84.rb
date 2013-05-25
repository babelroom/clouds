class HoboMigration84 < ActiveRecord::Migration
  def self.up
    remove_column :callees, :accept
    remove_column :callees, :destination
    remove_column :callees, :invitation_id
    remove_column :callees, :type
    remove_column :callees, :fail_reason
    remove_column :callees, :participant_email
    remove_column :callees, :ringing
    remove_column :callees, :answer
    remove_column :callees, :retries

    remove_index :callees, :name => :index_callees_on_invitation_id rescue ActiveRecord::StatementInvalid
  end

  def self.down
    add_column :callees, :accept, :decimal, :precision => 8, :scale => 1
    add_column :callees, :destination, :string
    add_column :callees, :invitation_id, :integer
    add_column :callees, :type, :string
    add_column :callees, :fail_reason, :string
    add_column :callees, :participant_email, :string
    add_column :callees, :ringing, :decimal, :precision => 8, :scale => 1
    add_column :callees, :answer, :decimal, :precision => 8, :scale => 1
    add_column :callees, :retries, :integer

    add_index :callees, [:invitation_id]
  end
end
