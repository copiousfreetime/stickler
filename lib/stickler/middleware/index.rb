require 'sinatra'
require 'stickler/middleware'
require 'stickler/middleware/helpers'
require 'stickler/repository/null'
require 'stickler/spec_lite'
require 'stickler/logable'
require 'stickler/paths'

module Stickler::Middleware
  # Index is a Rack middleware that passes all requests through except for those
  # matching these two urls:
  #
  # <b>/specs.#{Gem.marhsal_version}.gz</b>::         The [ name, version, platform ] index
  #                                                   of <b>all<b> the gems in the
  #                                                   entire repository
  #
  # <b>/latest_specs.#{Gem.marshal_version}.gz</b>::  The [ name, version, # platform ] index
  #                                                   of the <b>most recent</b> version of each
  #                                                   gem in the repository.
  #
  # For these 2 urls, it respond reponds with the summation of all the specs
  # that are in <tt>env['stickler.specs']</tt>.  If there are no specs in that
  # environment variable, then it returns with an empty index.
  #
  # == Options
  #
  # This class is also the base class for all the other GemServer type
  # middlewares, so there is an optional behavior to NOT respond to the index
  # url requests and just append the spec, or latest_specs to
  # env['stickler.specs'] instead of serving the values out of there.
  #
  # <b>:serve_indexes</b>::     +true+ or +false+ it defaults to +true+.  This
  #                             option is used when Index is used in a stack
  #                             with other Index derived  middlewares.  In this
  #                             case, all of the Index derived middlewares
  #                             should set <b>:serve_indexes => false</b> except
  #                             for the bottom one.  It should set
  #                             <b>:serve_indexes => true</b>.  This allows all
  #                             the Index derived middlewares to cooperatively
  #                             respond to the <b>/specs</b> and
  #                             </b>/latests_specs</b> urls.
  #
  # == Usage
  #
  # use Stickler::Middleware::Index, :serve_indexes => true
  # use Stickler::Middleware::Index, :serve_indexes => false
  #
  class Index < ::Sinatra::Base
    include Stickler::Middleware::Helpers::Compression
    include Stickler::Middleware::Helpers::Specs
    include Stickler::Logable

    # The respository of the Index is a Repository::Null
    attr_reader :repo

    server_path = Stickler::Paths.lib_path( "stickler", "server" )

    set :views,  File.join( server_path, "views" )
    set :public, File.join( server_path, "public" )
    set :static, true

    def initialize( app, opts = {} )
      @app           = app
      @repo          = ::Stickler::Repository::Null.new
      @serve_indexes = opts.has_key?( :serve_indexes ) ? opts[:serve_indexes] : true
      super( app )
    end

    before do
      response["Date"] = @repo.last_modified_time.rfc2822
      cache_control( 'no-cache' )
    end

    get '/' do
      append_specs
      if @serve_indexes then 
        erb :index
      else
        pass
      end
    end

    #
    # Respond to the requests for the <b>all gems</b> index
    #
    get %r{\A/specs.#{Gem.marshal_version}(\.gz)?\Z} do |with_compression|
      append_specs
      serve_indexes( with_compression )
    end

    #
    # Respond to the requests for the <b>latest gems</b> index
    #
    get %r{\A/latest_specs.#{Gem.marshal_version}(\.gz)?\Z} do |with_compression|
      append_latest_specs
      serve_indexes( with_compression )
    end

    #
    # Serve the indexes up as the response if @serve_indexes is true.  Otherwise
    # return false
    #
    def serve_indexes( with_compression = :none )
      if @serve_indexes then
        self.compression = to_compression_flag( with_compression )
        return marshalled_specs( specs )
      else
        pass
      end
    end

    #
    # Actually serve up the gem.  This is really only used by the child classes.
    # an Index instance will never have any gems to return.
    #
    get %r{\A/gems/(.*?)-([0-9.]+)(-.*?)?\.gem\Z} do
      name, version, platform = *params[:captures]
      spec = Stickler::SpecLite.new( name, version, platform )
      full_path = @repo.full_path_to_gem( spec )
      if full_path and File.exist?( full_path )then
        content_type 'application/x-tar'
        send_file( full_path )
      else
        pass
      end
    end

    #
    # Serve up a gemspec.  This is really only used by the child classes.
    # an Index instance will never have any gemspecs to return
    #
    get %r{\A/quick/Marshal.#{Gem.marshal_version}/(.*?)-([0-9.]+)(-.*?)?\.gemspec\.rz\Z} do
      name, version, platform, with_compression = *params[:captures]
      spec = Stickler::SpecLite.new( name, version, platform )
      full_path = @repo.full_path_to_specification( spec )
      if full_path and File.exist?( full_path ) then
        self.compression = :deflate # always compressed
        marshal( eval( IO.read( full_path ) ) )
      else
        pass
      end
    end

    #
    # Convert to the array format used by gem servers
    # everywhere
    #
    def marshalled_specs( spec_a )
      marshal( spec_a.collect { |s| s.to_rubygems_a } )
    end

    def marshal( data )
      content_type 'application/octet-stream'
      ::Marshal.dump( data )
    end

    def to_compression_flag( with_compression )
      return with_compression if [ :gzip, :deflate, :none ].include?( with_compression )
      return :gzip            if with_compression =~ /\.gz\Z/i
      return :deflate         if with_compression =~ /\.(Z|rz)\Z/i
      return :none
    end
  end
end
