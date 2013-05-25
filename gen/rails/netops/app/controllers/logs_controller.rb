class LogsController < ApplicationController

  hobo_model_controller

#  auto_actions :all

  def view
    @log = Log.find(params[:id])
    render :file => @log.path
  end

  def download
    @log = Log.find(params[:id])
    send_file @log.path, :type => @log.content_type, :filename => @log.name
    #send_file @log.path, :type => @log.content_type, :filename => @log.path, :stream => false
  end

end

