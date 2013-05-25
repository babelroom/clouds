class ConferencesController < ApplicationController

  hobo_model_controller

#  auto_actions :all
  def index
    @conferences = []
  end

end
