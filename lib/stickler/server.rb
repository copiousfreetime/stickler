require 'stickler/error'
require 'stickler/middleware/compression'
require 'stickler/middleware/gemcutter'
require 'stickler/middleware/mirror'
require 'stickler/middleware/index'
require 'stickler/middleware/not_found'
require 'rack/commonlogger'

module Stickler
  class Server

    # The directory holding all the repositories
    attr_reader :stickler_root

    def initialize( stickler_root )
      @stickler_root = File.expand_path( stickler_root )
      raise ::Stickler::Error, "Stickler root directory '#{@stickler_root}' must already exist" unless File.directory?( @stickler_root )
      raise ::Stickler::Error, "Stickler root directory '#{@stickler_root}' must be writable" unless File.writable?( @stickler_root )
    end

    def app
      root = self.stickler_root
      Rack::Builder.app do
        use Rack::CommonLogger
        use Stickler::Middleware::Compression
        use Stickler::Middleware::Gemcutter, :serve_indexes => false, :repo_root => File.join( root, "gemcutter" )
        use Stickler::Middleware::Mirror,    :serve_indexes => false, :repo_root => File.join( root, "mirror" )
        use Stickler::Middleware::Index,     :serve_indexes => true
        use Stickler::Middleware::NotFound
        run Sinatra::Base
      end
    end
 end
end
