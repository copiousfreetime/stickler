require 'rack/config'
require 'stickler/gem_server_deflater'
require 'stickler/mirror_manager_server'
require 'stickler/gem_server'

module Stickler
  class Web < ::Sinatra::Base

    set :gem_path   , Gem.path
    set :mirror_root, '/tmp/stickler'

    disable :sessions
    enable  :logging, :dump_errors, :clean_trace

    set :root, File.expand_path( File.join( File.dirname(__FILE__), '..' ) )

    use Stickler::GemServerDeflater
    use Stickler::MirrorManagerServer, :mirror_root => self.mirror_root
    use Stickler::GemServer, :gem_path => self.gem_path
  end
end
