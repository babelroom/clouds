class Log < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields do
    name         :string
    table        :string
    id_in_table  :integer
    content_type :string
    path         :string
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
