class Colmodel < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields do
    jqgrid_id   :string,    :length => 30
    elf         :string,    :length => 10
    colmodel    :text
    timestamps
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
