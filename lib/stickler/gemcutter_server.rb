require 'sinatra/base'
require 'rubygems/source_index'

module Stickler
  # 
  # A piece of middle ware to implement a small section of the gem cutter api
  #
  class GemcutterApiServer < ::Sinatra::Base
    def initialize( app = nil, options = {}  )
      @app = app
      super( app )
    end

    post '/api/vi/gems' do

    end
  end
end


