class ScriptFormatsController < ApplicationController

  hobo_model_controller

  auto_actions :index

  def index
    @script_formats = []
  end

end
