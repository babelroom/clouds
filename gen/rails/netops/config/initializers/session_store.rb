# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_netops_session',
  :secret      => '49e2c2acb88840efefd6fc508a9ebc661e632ef37abf8a976d9b5085bb38c7f47a4506b0188b61cb0d7c88dfd33fc32b56a349d1d92944c8f45f9002a4e01300'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
