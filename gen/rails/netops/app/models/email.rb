class Email < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields do
    email        :string
    origin_id    :integer, :index => true
    template     :string
    kv_pairs     :text
    content      :text
    progress     :string
    final_status :string
    timestamps
  end

  belongs_to    :system
  belongs_to    :person

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
