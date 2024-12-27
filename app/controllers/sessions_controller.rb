class SessionsController < ApplicationController
  def callback
    auth = request.env["omniauth.auth"]
    # ...
    redirect_to root_url
  end
end
