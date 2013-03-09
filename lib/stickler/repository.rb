module Stickler
  module Repository
    class Error < ::Stickler::Error ; end 
  end
end
require 'stickler/repository/api'
require 'stickler/repository/basic_authenticator'
require 'stickler/repository/index'
require 'stickler/repository/local'
require 'stickler/repository/mirror'
require 'stickler/repository/null'
require 'stickler/repository/remote'
require 'stickler/repository/remote_mirror'
require 'stickler/repository/rubygems_authenticator'
