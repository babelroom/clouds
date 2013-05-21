<<__ 
  belongs_to :owner, :class_name => "User", :creator => true
  validates_presence_of :email

  # --- Permissions --- #

  def create_permitted?
    acting_user.signed_up?
  end

  def update_permitted?
    acting_user.administrator?
  end

  def destroy_permitted?
    acting_user.administrator?
  end

  def view_permitted?(field)
    true
  end__>>
