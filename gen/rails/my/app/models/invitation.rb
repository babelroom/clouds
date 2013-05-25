class Invitation < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields do
    pin	:string
    dialin	:string
    role	:string
    token	:string, :index => true, :limit => 40
    created_at	:datetime
    updated_at	:datetime
    deployed_at	:datetime
    is_deleted	:boolean
  end

  belongs_to :conference
  belongs_to :user

  # --- Permissions --- #

  def create_permitted?
    acting_user.administrator?
  end

  def update_permitted?
    acting_user.administrator?
  end

  def destroy_permitted?
    acting_user.administrator?
  end

  def view_permitted?(field)
    true
  end

end

