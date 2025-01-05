class SessionsController < ApplicationController
  def callback
    auth = request.env["omniauth.auth"]
    user = User.find_by(uid: auth.uid) || User.new(uid: auth.uid)
    user.assign_attributes(
      token: auth.credentials.token,
      expires_on: DateTime.strptime(auth.info.expires_on.to_s, "%s"),
      name: auth.info.name,
     character_id: auth.info.character_id
    )
    user.save!
    redirect_to root_url
  end
end
