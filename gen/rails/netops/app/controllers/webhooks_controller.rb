class WebhooksController < ApplicationController

  def incoming
    wh = Webhook.new(:uri => params[:uri], :json => params.to_json, :body => request.env['RAW_POST_DATA'] )
    if wh.save()
        render :text => 'OK', :status => 200
    else
        render :text => 'Internal Error', :status => 500
    end
  end
end

