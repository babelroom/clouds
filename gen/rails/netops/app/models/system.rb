class System < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields do
    name    :string
    system_type :string
    config_key  :string
    access  :string
    notes   :text
#    cluster :string
#    group   :string
    timestamps
  end

  has_many :server_services, :dependent => :destroy
  has_many :services, :through => :server_services
  has_many :conferences, :dependent => :destroy
  has_many :people, :dependent => :destroy
  # TODO -- reconsider all these dependent => destroy stuff
  has_many :emails, :dependent => :destroy

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
