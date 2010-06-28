require 'sinatra'
require 'stickler/repository/local'
module Stickler
  #
  # An Sinatra middleware that implments the HTTP server for the modern gem server as
  # listed in the Gem::Server class.  This middleware will respond to requests
  # that are issued by 'gem --remote-install'
  #
  # <b>/specs.#{Gem.marhsal_version}.gz</b>::         The [ name, version, platform ] index
  #                                                   of *all* the gems in the
  #                                                   entire repository
  #
  # <b>/latest_specs.#{Gem.marshal_version}.gz</b>::  The [ name, version, # platform ] index
  #                                                   of the <b>most recent</b> version of each
  #                                                   gem in the repository.
  #
  # <b>/gems/<gem-version-platform>.gem::             The direct download url of
  #                                                   a gem in the repository
  #
  # It utilizies a Stickler::Repository::Local, and then :repo_root option
  # is passed directoy to it.
  #
  # A GemServer can be used in a stack with other GemServer's that are serving
  # other repositories or a GemServer derivative class.  In this case, since
  # all the GemServer's could respond to the /specs
  #
  # A GemServer may also not have a repository attached to it.  In this case
  # it returns empty indexes for <b>/specs</b> and <b>/latest_specs</b> urls
  # and 404's for anything else.
  #
  # == Options
  #
  # <b>:serve_indexes</b>::     +true+ or +false+ it defaults to +true+.  This
  #                             option is used when GemServer is used in a stack
  #                             with other GemServer middlewares.  In this case,
  #                             all of the GemServer middlewares should set
  #                             <b>:serve_indexes => false</b> except for the
  #                             bottom one.  It should set <b>:serve_indexes
  #                             => true</b>.  This allows all the GemServer
  #                             middlewares to cooperatively respond to the
  #                             <b>/specs</b> and </b>/latests_specs</b> urls.
  #
  # <b>:repo_root</b>:;         The path that is to be the root of the
  #                             Repository instance managed by this server.
  #
  # == Usage
  #
  #   use Stickler::GemServer, :repo_root => '/path/to/repository'
  #
  class GemServer < ::Sinatra::Base
    def initialize( app = nil, opts = {} )
      @repo_root = opts[:repo_root]
      @repo      = @repo_root ? Repository::Local
      @repo            = opts.has_key?(:repo_root)     ? opts[:repo_root]
      @append_to_index = opts.has_key?(:serve_indexes) ? opts[:serve_indexes] : false
      super( app )
    end

    before do
      response["Date"] = @repo.last_modified_time.rfc2822
      response['Cache-Control'] = 'no-cache'
    end

    get '/' do
      erb :index
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
      full_path = @repo.full_path_to_gem( spec )
      if full_path then
        content_type 'application/x-tar'
        send_file( full_path )
      else
        not_found( "Gem #{spec.file_name} is not found " )
      end
    end

  end
end
