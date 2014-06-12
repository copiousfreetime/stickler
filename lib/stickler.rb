module Stickler
  # The Current Version of the library
  VERSION = "2.4.1"
end
require 'sinatra/base'

require 'stickler/logable'
require 'stickler/error'
require 'stickler/paths'
require 'stickler/spec_lite'
require 'stickler/gem_container'
require 'stickler/gemfile_lock_parser'

require 'stickler/repository'
require 'stickler/middleware'
require 'stickler/server'
