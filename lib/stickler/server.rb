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
      Rack::Builder.app( Sinatra::Base.new ) do
        use Rack::CommonLogger
        use Stickler::Middleware::Server, :stickler_root => root
        use Stickler::Middleware::NotFound
      end
    end
  end
end
