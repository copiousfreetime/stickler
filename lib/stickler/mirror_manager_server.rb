require 'sinatra/base'
require 'stickler/mirror_manager'

module Stickler
  class MirrorManagerServer< ::Sinatra::Base

    # The root directory all local mirrors of upstream repos will be stored.
    # Each mirror will have a directory within the mirror_root
    attr_reader :mirror_manager

    def initalize( app, options = {} )
      @app = app
      @mirror_manager = MirrorManager.new( options[:mirror_root] )
    end

    def gem_full_name( params )
      parts = [ params[:name] ]
      parts << params[:version]  if params[:version]
      parts << params[:platform] if params[:platform]
      parts.join('-')
    end

    get '/:source/:name/:version/:platform' do
      mirror = mirror_manager.for( params[:source] )
      if spec = mirror.add_gem( params ) then
        redirect "/gems/#{gem.file_name}"
      else
        not_found "Unable to find gem [#{gem_full_name}] at source #{params[:source]}"
      end
    end
  end
end

