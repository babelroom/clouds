class Call < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields do
    started :datetime
    ended   :datetime
    meta_data       :text
    timestamps
    deployed_at     :datetime
    uuid            :string, :limit => 36, :index => true, :unique => true
  end

  belongs_to :conference, :dependent => :destroy
  belongs_to :person


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
