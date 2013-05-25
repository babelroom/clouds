class Person < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields do
    name            :string
    last_name       :string
    dialout         :string
    email           :string, :index => true
    pin             :string
    dialin          :string    # big enough for full text? -- match with invitation table in provisioning
    configuration   :string
    timestamps
    is_deleted      :boolean
    deployed_at     :datetime
    origin_id       :string, :index => true
    fs_server       :string
    token           :string, :limit => 40, :index => true
  end

  belongs_to :system, :dependent => :destroy
  belongs_to :conference
  has_many :emails
  has_many :calls

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
