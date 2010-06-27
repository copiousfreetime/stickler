require 'sinatra/base'
require 'stickler/repository/mirror'

module Stickler
  class MirrorServer < ::Sinatra::Base

    # The root directory all local mirrors of upstream repos will be stored.
    # Each mirror will have a directory within the mirror_root
    attr_reader :mirror

    def initialize( app, options = {} )
      @app = app
      @mirror = Repository::Mirror.new( options[:mirror_root] )
      puts "Mirror manager server with root dir #{options[:mirror_root]}"
      super( app )
    end

    def manage( params )
      puts "MirrorManager called #{params.inspect}"
      host = params[:source]
      spec = Stickler::SpecLite.new( params[:name], params[:version], params[:platform] )

      begin
        if spec = mirror.mirror( host , spec ) then
          status 201
          response["Location"] = "/gems/#{spec.file_name}"
          nil
        else
          not_found "Unable to find gem [#{spec.full_name}] at source #{host}"
        end
      rescue Stickler::Repository::Mirror::Error => e
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


