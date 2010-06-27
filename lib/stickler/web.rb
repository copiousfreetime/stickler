require 'stickler/gem_server_deflater'
require 'stickler/gem_server'

module Stickler
  class Web < ::Sinatra::Base

    disable :sessions
    enable  :logging, :dump_errors, :clean_trace

    set :root, File.expand_path( File.join( File.dirname(__FILE__), %w[ .. .. ] ) )

    use Stickler::GemServerDeflater
    use Stickler::GemServer, :repo_root => File.join( self.root, "spec", "data" )
  end
end
