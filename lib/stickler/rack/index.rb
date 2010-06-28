require 'sinatra'
require 'stickler/rack'
require 'stickler/rack/helpers'
require 'stickler/repository/null'

module Stickler::Rack
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
  # use Stickler::Rack::Index, :serve_indexes => true
  # use Stickler::Rack::Index, :serve_indexes => false
  #
  class Index < ::Sinatra::Base
    include Stickler::Rack::Helpers::Compression
    include Stickler::Rack::Helpers::Specs

    # The respository of the Index is a Repository::Null
    attr_reader :repo

    def initialize( app, opts = {} )
      @app           = app
      @repo          = ::Stickler::Repository::Null.new
      @serve_indexes = opts.has_key?( :serve_indexes ) ? opts[:serve_indexes] : true
      super( app )
    end

    #
    # Respond to the requests for the <b>all gems</b> index
    #
    get %r{\A/specs.#{Gem.marshal_version}(\.gz)?\Z} do |with_compression|
      serve_indexes( with_compression ) #|| append_specs
    end

    #
    # Respond to the requests for the <b>latest gems</b> index
    #
    get %r{\A/latest_specs.#{Gem.marshal_version}(\.gz)?\Z} do |with_compression|
      serve_indexes( with_compression ) #|| append_latest_specs
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
        return false
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
