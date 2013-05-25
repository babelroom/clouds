class Script < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields do
    name        :string
    version     :timestamp
    is_deleted  :boolean
    description :text
    startup     enum_string(:never, :one, :manual)
    timestamps
  end

  belongs_to :script_format

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
