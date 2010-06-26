require 'sinatra/base'
require 'stickler/repository/local'

module Stickler
  # 
  # A piece of middle ware to implement a small section of the gem cutter api
  #
  class GemcutterApiServer < ::Sinatra::Base
    def initialize( app = nil, options = {}  )
      @app = app
      @repo = Stickler::Repository::Local.new( options[:repo_root] )
      super( app )
    end

    post '/api/v1/gems' do

    end

    delete '/api/v1/yank' do

    end
  end
end


