class InterconnectsController < ApplicationController

  hobo_model_controller

  auto_actions :all

  def index
    @interconnects = []
  end

end

