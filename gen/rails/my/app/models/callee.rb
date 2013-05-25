class Callee < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields do
    started	:datetime
    ended	:datetime
    participant	:string
    created_at	:datetime
    updated_at	:datetime
    number	:string
    meta_data	:text
    accounting_code	:string
    accounting_desc	:string
    notes	:string
    external_id	:string
  end

  belongs_to :conference
  belongs_to :account

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

