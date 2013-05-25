class Job < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields do
    name       :string
    script_name :string
    pid        :integer
    parameters :text
    started    :timestamp
    ended      :timestamp
    status     :string
    timestamps
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
