require 'sinatra/base'
require 'stickler/middleware'
require 'stickler/middleware/index'
require 'stickler/repository/local'

module Stickler::Middleware
  # 
  # A rack middleware for implementing the gemcutter api
  #
  class Gemcutter < ::Stickler::Middleware::Index
    include Stickler::Middleware::Helpers::Compression
    include Stickler::Middleware::Helpers::Specs

    def initialize( app = nil, options = {}  )
      super( app, options )
      @repo = Stickler::Repository::Local.new( options[:repo_root] )
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


