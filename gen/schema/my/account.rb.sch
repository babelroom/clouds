<<__
  belongs_to :owner, :class_name => "User", :creator => true
  has_many :conferences
  has_one :billing_record, :dependent => :destroy

  # --- Permissions --- #

  def create_permitted?
    acting_user.administrator?
  end

  def update_permitted?
#    acting_user.administrator?
    acting_user.signed_up?
  end

  def destroy_permitted?
    acting_user.administrator?
  end

  def view_permitted?(field)
    true
  end__>>
