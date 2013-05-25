class Phone < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields do
    identifier	:string
    phone_type	:string
    dial_options	:string
    call_options	:string
    sms_carrier	:string
    sms_identifier	:string
    extension	:string
    delay	:integer, :default => 0
    dial_timeout	:integer, :default => 45
    acknowledgement	:boolean, :default => true
    created_at	:datetime
    updated_at	:datetime
  end

  validates_presence_of [:identifier, :type]
  belongs_to :owner, :class_name => "User", :creator => true

  # --- Permissions --- #

  def create_permitted?
    acting_user.administrator?
  end

  def update_permitted?
    acting_user.signed_up?
#    acting_user.administrator?
  end

  def destroy_permitted?
    acting_user.signed_up?
#    acting_user.administrator?
  end

  def view_permitted?(field)
    true
  end

end

