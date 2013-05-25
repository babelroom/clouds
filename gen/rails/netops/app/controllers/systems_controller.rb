class SystemsController < ApplicationController

  hobo_model_controller

  auto_actions :all

  def index
    @systems = []
  end

end

