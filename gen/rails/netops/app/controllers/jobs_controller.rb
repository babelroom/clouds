class JobsController < ApplicationController

  hobo_model_controller

  auto_actions :index, :new, :create

  def new
    script = Script.find(params[:id])
    job = Job.new
    job[:name] = script[:name]
    job[:script_name] = script[:name]
    hobo_new(job)
  end

  def index
    @jobs = []
  end

end

