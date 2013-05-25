class Conference < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields do
    name            :string
    schedule        :string
    start           :datetime
    timestamps
    state           :string
    is_deleted      :boolean    # depreciate? -- yes do
    origin_id       :string, :index => true
    fs_server       :string
    actual_start    :datetime
    actual_end      :datetime
    conference_key  :string
  end

  belongs_to :system, :dependent => :destroy
#  has_many :people
  has_many :calls
  has_many :media_files

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
