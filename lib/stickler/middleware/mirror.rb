require 'sinatra/base'
require 'stickler/middleware/index'
require 'stickler/repository/mirror'

module Stickler::Middleware
  #
  # A Mirror server keeps gems from one or more upstream gem servers in local
  # repositories.
  #
  class Mirror < ::Stickler::Middleware::Index
    # The mirror repository
    attr_reader :repo

    def initialize( app, options = {} )
      super( app )
      @repo = ::Stickler::Repository::Mirror.new( options[:repo_root] )
    end

    def manage( params )
      host = params[:source]
      spec = Stickler::SpecLite.new( params[:name], params[:version], params[:platform] )

      begin
        if spec = @repo.mirror( host , spec ) then
          status 201
          response["Location"] = "/gems/#{spec.file_name}"
          nil
        else
          not_found "Unable to find gem [#{spec.full_name}] at source #{host}"
        end
      rescue ::Stickler::Repository::Mirror::Error => e
        error( 409, e.message )
      end
    end

    post '/:source/:name/:version/:platform' do
      manage( params )
    end

    post '/:source/:name/:version' do
      manage( params )
    end
  end
end


