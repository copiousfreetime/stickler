require 'rack/utils'
require 'stickler/middleware'
module Stickler::Middleware
  class Compression
    def initialize( app )
      @app = app 
    end

    def call( env )
      status, headers, body = @app.call( env )
      return [ status, headers, body ] unless status == 200

      headers = ::Rack::Utils::HeaderHash.new( headers )
      stream  = body

      if compress_method = env['stickler.compression'] then
        headers.delete('Content-Length')
        case compress_method
        when :gzip
          headers['Content-Type'] = 'application/x-gzip'
          stream = Gem.gzip( body.first )
        when :deflate
          headers['Content-Type'] = 'application/x-deflate'
          stream = Gem.deflate( body.first )
        end
      end
      stream = [ stream.to_s ] unless stream.respond_to?( :each )
      return [ status, headers, stream ]
    end
  end
end
