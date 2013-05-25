class BillingRecord < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields do
    title	:string
    legal_name	:string
    attention	:string
    address1	:string
    address2	:string
    city	:string
    state	:string
    zip	:string
    country	:string
    phone	:string
    url	:string
    code	:string
    billing_address1	:string
    billing_address2	:string
    billing_city	:string
    billing_state	:string
    billing_country	:string
    billing_zip	:string
    billing_phone	:string
    created_at	:datetime
    updated_at	:datetime
  end

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

