class Conference < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields do
    name	:string
    start	:datetime
    config	:string
    created_at	:datetime
    updated_at	:datetime
    deployed_at	:datetime
    is_deleted	:boolean
    schedule	:string
    pin	:string
    actual_start	:datetime
    actual_end	:datetime
    participant_emails	:text, :limit => 2147483647
    uri	:string, :index => true
    introduction	:text
    access_config	:text
    origin_data	:string
    origin_id	:integer
  end

  has_many :callees, :dependent => :destroy
  belongs_to    :owner, :class_name => "User", :creator => true
  belongs_to    :account
  belongs_to    :skin
  has_many :invitations, :class_name => "Invitation", :dependent => :destroy
  has_many :invitees, :through => :invitations, :source => :user
  has_many :media_files, :dependent => :destroy

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

