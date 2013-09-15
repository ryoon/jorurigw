# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
#ActionController::Base.session = {
#  :key         => '_gw_rails_2.3.4_session',
#  :secret      => 'a530208ed01424e5f09f110f4e187889e9c1e78e8664798d7e4d7c3af4b4d5e92943ebcc13e41e8e3b7d2cca9595cbd139025955ce195a6f3ee79bc18f948964'
#}
ActionController::Base.session = {
    :session_key => '_jgw_session',
    :secret      => 'a6a95500f19ac4287f76b06dfbcf548e9fac1fae64a22cd774094c1db036be8601f3e1531c37c004eb3fed1bb0f9d23d543bd280ffdaeb4229ac73b25e8a53aa',
    :cookie_only => false,
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
ActionController::Base.session_store = :active_record_store
