<<__
  validates_presence_of [:identifier, :type]
  belongs_to :owner, :class_name => "User", :creator => true

  # --- Permissions --- #

  def create_permitted?
    acting_user.administrator?
  end

  def update_permitted?
    acting_user.signed_up?
#    acting_user.administrator?
  end

  def destroy_permitted?
    acting_user.signed_up?
#    acting_user.administrator?
  end

  def view_permitted?(field)
    true
  end__>>
