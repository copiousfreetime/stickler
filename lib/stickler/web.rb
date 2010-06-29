require 'stickler/middleware/compression'
require 'stickler/middleware/gemcutter'
require 'stickler/middleware/mirror'
require 'stickler/middleware/index'
require 'rack/cascade'

module Stickler
  class Web < ::Sinatra::Base

    disable :sessions
    enable  :logging, :dump_errors, :clean_trace

    use Stickler::Middleware::Compression
    use Stickler::Middleware::Gemcutter, :serve_indexes => false
    use Stickler::Middleware::Mirror,    :serve_indexes => false
    use Stickler::Middleware::Index,     :serve_indexes => true
    run Stickler::Middleware::NotFound
  end
end
