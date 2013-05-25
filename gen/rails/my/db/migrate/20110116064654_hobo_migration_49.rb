class HoboMigration49 < ActiveRecord::Migration
  def self.up
    create_table :invitations do |t|
      t.string   :pin
      t.string   :role
      t.datetime :created_at
      t.datetime :updated_at
      t.integer  :conference_id
      t.integer  :user_id
    end
    add_index :invitations, [:conference_id]
    add_index :invitations, [:user_id]

    remove_column :users, :conference_id

    remove_index :users, :name => :index_users_on_conference_id rescue ActiveRecord::StatementInvalid
  end

  def self.down
    add_column :users, :conference_id, :integer

    drop_table :invitations

    add_index :users, [:conference_id]
  end
end
