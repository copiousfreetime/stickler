require 'rack/deflater'
require 'rack/utils'
require 'pp'

module Stickler
  class GemServerDeflater
    def initialize( app )
      @app = app 
    end

    def call( env )
      status, headers, body = @app.call( env )
      return [ status, headers, body ] unless status == 200

      headers = ::Rack::Utils::HeaderHash.new( headers )
      stream  = body

      if compress_method = env['stickler.compress'] then
        headers.delete('Content-Length')
        headers['Content-Encoding'] = compress_method
        case compress_method
        when 'gzip'
          puts "Gzipping output"
          stream = ::Rack::Deflater::GzipStream.new( body, Time.now )
        when 'deflate'
          puts "Deflating output"
          stream = ::Rack::Deflater::DeflateStream.new( body )
        else
          headers.delete('Content-Encoding')
        end
      end

      return [ status, headers, stream ]
    end
  end
end
