class Token < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields do
    template	:string
    link_key	:string
    expires	:datetime
    is_deleted	:boolean
    created_at	:datetime
    updated_at	:datetime
  end

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

