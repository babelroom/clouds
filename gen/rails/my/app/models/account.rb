class Account < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields do
    name	:string
    balance	:decimal, :scale => 2, :precision => 8
    balance_limit	:decimal, :scale => 2, :precision => 8
    max_call_rate	:decimal, :scale => 2, :precision => 8
    max_users	:integer, :default => 100
    max_duration	:integer, :default => 240
    rec_notification	:string
    rec_policy	:string
    external_code	:string
    external_token	:string
    rec_min	:integer
    rec_max	:integer
    suppress_charges_col	:boolean
    plan_code	:string
    plan_description	:text
    plan_usage	:text
    plan_last_invoice	:string
    change_to_plan_code	:string
    changing_flag	:boolean
    created_at	:datetime
    updated_at	:datetime
  end

  belongs_to :owner, :class_name => "User", :creator => true
  has_many :conferences
  has_one :billing_record, :dependent => :destroy

  # --- Permissions --- #

  def create_permitted?
    acting_user.administrator?
  end

  def update_permitted?
#    acting_user.administrator?
    acting_user.signed_up?
  end

  def destroy_permitted?
    acting_user.administrator?
  end

  def view_permitted?(field)
    true
  end

end

