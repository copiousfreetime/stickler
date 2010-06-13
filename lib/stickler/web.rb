require 'rack/config'
require 'stickler/gem_server_deflater'
require 'stickler/gem_server'

module Stickler
  class Web < ::Sinatra::Base
    set :gem_path, Gem.path

    use Stickler::GemServerDeflater
    use Stickler::GemServer, :gem_path => self.gem_path
  end
end
