class HoboMigration37 < ActiveRecord::Migration
  def self.up
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
    add_column :users, :timezone, :string, :default => "US/Pacific"
    add_column :users, :company, :string
    add_column :users, :pin, :string
    add_column :users, :call_host, :string
    add_column :users, :call_non_host, :string
    add_column :users, :call_me_from, :string
    add_column :users, :call_me_to, :string
    add_column :users, :call_summary_dest, :string
    add_column :users, :encrypt_pages, :boolean
    add_column :users, :suppress_notifications, :boolean
    add_column :users, :spam_trap_workaround, :boolean
    add_column :users, :conference_id, :integer

    add_index :users, [:conference_id]
  end

  def self.down
    remove_column :users, :first_name
    remove_column :users, :last_name
    remove_column :users, :timezone
    remove_column :users, :company
    remove_column :users, :pin
    remove_column :users, :call_host
    remove_column :users, :call_non_host
    remove_column :users, :call_me_from
    remove_column :users, :call_me_to
    remove_column :users, :call_summary_dest
    remove_column :users, :encrypt_pages
    remove_column :users, :suppress_notifications
    remove_column :users, :spam_trap_workaround
    remove_column :users, :conference_id

    remove_index :users, :name => :index_users_on_conference_id rescue ActiveRecord::StatementInvalid
  end
end
