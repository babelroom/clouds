class Colmodel < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields do
    jqgrid_id	:string, :limit => 30
    elf	:string, :limit => 10
    colmodel	:text
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

