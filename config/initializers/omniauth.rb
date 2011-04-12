require "openid/store/filesystem"

Rails.application.config.middleware.use OmniAuth::Builder do
#  provider :facebook, "183986118304383", "8ed294c3702de58b2fbdfa8cc0c2ca29"
  provider :facebook, "201216816578155", "60329925efa6879838b0d8df31511c2e" #localhost
  provider :open_id, OpenID::Store::Filesystem.new('/tmp')
#  provider :twitter, "183986118304383", "8ed294c3702de58b2fbdfa8cc0c2ca29"
end