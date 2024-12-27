OmniAuth.config.allowed_request_methods = [ :get, :post ]

Rails.application.config.middleware.use OmniAuth::Builder do
  OmniAuth.config.full_host = "http://localhost:3000"
  provider :developer unless Rails.env.production?
  provider :eve_online_sso,
           ENV["EVE_CLIENT_ID"],
           ENV["EVE_SECRET_KEY"],
           scope: "publicData",
           callback_path: "/auth/eve_online_sso/callback"
end
