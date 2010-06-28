require 'sinatra'
require 'stickler/middleware'
require 'stickler/middleware/index'
require 'stickler/repository/local'

module Stickler::Middleware
  #
  # A Sinatra middleware that implements the HTTP portions of a Modern gem server.  
  # It sits on top of a Repository::Local and serves up the gems in it.
  #
  # It utilizies a Stickler::Repository::Local, and the :repo_root option
  # is passed directly to it.
  #
  # == Options
  #
  # <b>:serve_indexes</b>::   the same as the Index middleware
  #
  # <b>:repo_root</b>::       The path that is to be the root of the
  #                           Repository instance managed by this server.
  #
  # The <b>:repo_root</b> option is required.
  #
  # == Usage
  #
  #   use Stickler::Middleware::RepoLocal, :repo_root => '/path/to/repository'
  #
  #   use Stickler::Middleware::RepoLocal, :repo_root => '/path/to/repository',
  #                                        :serve_indexes => true
  #
  class RepoLocal < Index
    def initialize( app = nil, opts = {} )
      super( app, opts )
      # overwrite the repo that is set in the parent
      @repo      = Repository::Local.new( opts[:repo_root] )
    end

    before do
      response["Date"] = @repo.last_modified_time.rfc2822
      cache_control( 'no-cache' )
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
