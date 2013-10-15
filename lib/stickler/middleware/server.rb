require 'pathname'
module Stickler::Middleware
  # Server is the entire stickler stack as a single piece of middleware that
  # may be used by other libraries that would like to include Stickler in their
  # application.
  class Server
    attr_reader :stickler_root

    def initialize( app, opts = {} )
      @app            = app
      @stickler_root  = Pathname.new( opts.fetch( :stickler_root ) ).realpath
      @run            = server_app
      validate
    end

    def call( env )
      @run.call( env )
    end

    def server_app
      root = self.stickler_root
      Rack::Builder.app( @app )do
        use Stickler::Middleware::Compression
        use Stickler::Middleware::Gemcutter, :serve_indexes => false, :repo_root => root.join( "gemcutter" )
        use Stickler::Middleware::Mirror,    :serve_indexes => false, :repo_root => root.join( "mirror" )
        use Stickler::Middleware::Index,     :serve_indexes => true
      end
    end

    private

    def validate
      raise ::Stickler::Error, "Stickler root directory '#{stickler_root}' must already exist" unless stickler_root.directory?
      raise ::Stickler::Error, "Stickler root directory '#{stickler_root}' must be writable" unless stickler_root.writable?
    end
  end
end
