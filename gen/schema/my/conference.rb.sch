<<__
  has_many :callees, :dependent => :destroy
  belongs_to    :owner, :class_name => "User", :creator => true
  belongs_to    :account
  belongs_to    :skin
  has_many :invitations, :class_name => "Invitation", :dependent => :destroy
  has_many :invitees, :through => :invitations, :source => :user
  has_many :media_files, :dependent => :destroy

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
