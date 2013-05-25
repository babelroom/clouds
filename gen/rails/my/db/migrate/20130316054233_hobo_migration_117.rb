class HoboMigration117 < ActiveRecord::Migration
  def self.up
    remove_column :users, :call_non_host
    remove_column :users, :call_me_to
    remove_column :users, :call_me_from
    remove_column :users, :suppress_notifications
    remove_column :users, :call_host
    remove_column :users, :encrypt_pages
    remove_column :users, :spam_trap_workaround
    remove_column :users, :call_summary_dest
  end

  def self.down
    add_column :users, :call_non_host, :string
    add_column :users, :call_me_to, :string
    add_column :users, :call_me_from, :string
    add_column :users, :suppress_notifications, :boolean
    add_column :users, :call_host, :string
    add_column :users, :encrypt_pages, :boolean
    add_column :users, :spam_trap_workaround, :boolean
    add_column :users, :call_summary_dest, :string
  end
end
