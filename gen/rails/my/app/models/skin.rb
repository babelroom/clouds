class Skin < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields do
    name	:string, :required, :unique
    immutable	:boolean, :default => false
    preview_url	:string
    body	:text
    created_at	:datetime
    updated_at	:datetime
  end

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

