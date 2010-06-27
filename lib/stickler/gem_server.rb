require 'sinatra'
require 'stickler/repository/local'
module Stickler
  #
  # An Sinatra middleware that implments the HTTP server for the modern gem server as
  # listed in the Gem::Server class.  This middleware will respond to requests
  # that are issued by 'gem --remote-install'
  #
  # * "/specs.#{Gem.marshal_version}.gz" - specs name/version/platform index
  # * "/latest_specs.#{Gem.marshal_version}.gz" - only the latest name/version/platform 
  # * "/gems/<gem-version-platform>.gem - direct access to the gem files
  #
  # It utilizies a Stickler::Repository::Local, and then :repo_root option
  # is passed directoy to it.
  #
  # == Usage
  #
  #   use Stickler::GemServer, :repo_root => '/path/to/repository'
  class GemServer < ::Sinatra::Base
    def initialize( app = nil, opts = {} )
      @repo = Repository::Local.new( opts[:repo_root ] )
      super( app )
    end

    before do
      response["Date"] = @repo.last_modified_time.rfc2822
      response['Cache-Control'] = 'no-cache'
    end

    get '/' do
      erb :index
    end

    get "/specs-now" do
      @repo.specs.to_yaml
    end
    get %r{\A/specs.#{Gem.marshal_version}(\.gz)?\Z} do |gzip|
      env['stickler.compress'] = 'gzip' if gzip
      marshalled_specs( @repo.specs )
    end

    get %r{\A/latest_specs.#{Gem.marshal_version}(\.gz)?\Z} do |gzip|
      env['stickler.compress'] = 'gzip' if gzip
      marshalled_specs( @repo.latest_specs )
    end

    #
    # Actually serve up the gem
    #
    get %r{\A/gems/(.*?)-([0-9.]+)(-.*?)?\.gem\Z} do
      name, version, platform = *params[:captures]
      spec = Stickler::SpecLite.new( name, version, platform )
      full_path = @repo.gem_filename( spec )
      if full_path then
        content_type 'application/x-tar'
        send_file( full_path )
      else
        not_found( "Gem #{spec.file_name} is not found " )
      end
    end

    # Convert to the array format used by gem servers
    # everywhere
    def marshalled_specs( specs )
      marshal( specs.collect { |s| s.to_rubygems_a } )
    end

    def marshal( data )
      content_type 'application/octet-stream'
      ::Marshal.dump( data )
    end
  end
end
