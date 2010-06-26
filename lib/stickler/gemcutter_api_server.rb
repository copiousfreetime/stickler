require 'sinatra/base'
require 'stickler/repository/local'

module Stickler
  # 
  # A piece of middle ware to implement a small section of the gem cutter api
  #
  class GemCutterApiServer < ::Sinatra::Base
    def initialize( app = nil, options = {}  )
      @app = app
      @repo = Stickler::Repository::Local.new( options[:repo_root] )
      super( app )
    end

    post '/api/v1/gems' do
      begin
        spec = @repo.add( request.body )
        spec.to_s
      rescue Stickler::Repository::Error => e
        error( 500, "Error adding gem to repo: #{e}" )
      end
    end

    delete %r{\A/gems/((.*?)-([0-9.]+)(-.*?)?)\.gem\Z} do
      full_name, name, version, platform = *params[:captures]
      spec = Stickler::SpecLite.new( name, version, platform )
      @repo.delete( spec )
      return "deleted gem #{spec.full_name}"
    end

    delete '/api/v1/gems/yank' do
      spec = Stickler::SpecLite.new( params[:gem_name], params[:version] )
      if s = @repo.yank( spec ) then
        "Yanked #{s.to_s}"
      else
        error( 503, "Did not Yank #{spec.to_s}" )
      end
    end
  end
end


