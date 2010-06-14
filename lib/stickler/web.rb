require 'rack/config'
require 'stickler/gem_server_deflater'
require 'stickler/mirror_manager_server'
require 'stickler/gem_server'

module Stickler
  class Web < ::Sinatra::Base

    set :gem_path   , '/Users/jeremy/Projects/stickler2/spec/data'
    set :mirror_root, '/tmp/stickler'

    use Stickler::GemServerDeflater
    #use Stickler::MirrorManagerServer, :mirror_root => self.mirror_root
    use Stickler::GemServer, :gem_path => self.gem_path
  end
end
