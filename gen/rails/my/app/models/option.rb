class Option < ActiveRecord::Base

  hobo_model # Don't put anything above this

  fields do
    table	:string, :required, :unique
    table_id	:integer
    name	:string, :required, :unique
    value	:string
    created_at	:datetime
    updated_at	:datetime
  end


end

