require 'rack/config'
require 'stickler/gem_server_deflater'
require 'stickler/gem_server'

module Stickler
  class Web < ::Sinatra::Base
    use Stickler::GemServerDeflater
    use Stickler::GemServer, :gem_path => Gem.path
  end
end
