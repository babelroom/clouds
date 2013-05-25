class Pin < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields do
    created_at	:datetime
    updated_at	:datetime
    pin	:string, :unique => true, :index => true, :limit => 6
    invitation_id	:integer
  end


end

