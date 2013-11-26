class HoboMigration126 < ActiveRecord::Migration
  def self.up
    create_table :stream_refs do |t|
      t.datetime :created_at
      t.datetime :updated_at
    end

    create_table :streams do |t|
      t.datetime :created_at
      t.datetime :updated_at
    end

    change_column :conferences, :skin_id, :integer, :limit => 4, :default => nil

    add_column :users, :ephemeral_context, :string

    remove_index :tokens, :name => :index_email_requests_on_user_id rescue ActiveRecord::StatementInvalid
  end

  def self.down
    change_column :conferences, :skin_id, :integer, :default => 1

    remove_column :users, :ephemeral_context

    drop_table :stream_refs
    drop_table :streams

    add_index :tokens, [:user_id], :name => 'index_email_requests_on_user_id'
  end
end
