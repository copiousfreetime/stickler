require 'sinatra/base'
require 'stickler/mirror_manager'

module Stickler
  class MirrorManagerServer < ::Sinatra::Base

    # The root directory all local mirrors of upstream repos will be stored.
    # Each mirror will have a directory within the mirror_root
    attr_reader :mirror_manager

    def initialize( app, options = {} )
      @app = app
      @mirror_manager = MirrorManager.new( options[:mirror_root] )
      puts "Mirror manager server with root dir #{options[:mirror_root]}"
      super( app )
    end

    def gem_full_name( params )
      parts = [ params[:name] ]
      parts << params[:version]  if params[:version]
      parts << params[:platform] if params[:platform]
      parts.join('-')
    end

    def manage( params )
      puts "MirrorManager called #{params.inspect}"
      mirror = mirror_manager.for( params[:source] )
      if spec = mirror.add_gem( params ) then
        puts "redirecting to /gems/#{spec.file_name}"
        redirect "/gems/#{spec.file_name}"
      else
        not_found "Unable to find gem [#{gem_full_name}] at source #{params[:source]}"
      end
    end

    # put all the gem paths into the env so that everyone else can use it
    before do
      puts "setting gem_path -> #{mirror_manager.gem_path}"
      env['stickler.gem_path'] = mirror_manager.gem_path
    end

    get '/:source/:name/:version/:platform' do
      manage(params)
    end

    get '/:source/:name/:version' do
      manage(params)
    end
  end
end

