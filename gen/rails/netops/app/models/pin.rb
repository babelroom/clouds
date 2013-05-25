class Pin < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields do
    pin             :string, :limit => 6, :index => true, :unique => true
    email           :string
    person_id       :integer
    conference_id   :integer
    system_id       :integer
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
