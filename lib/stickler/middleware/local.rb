require 'stickler/middleware/index'
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
  #   use Stickler::Middleware::Local, :repo_root => '/path/to/repository'
  #
  #   use Stickler::Middleware::Local, :repo_root => '/path/to/repository',
  #                                    :serve_indexes => true
  #
  class Local < Index
    def initialize( app = nil, opts = {} )
      super( app, opts )
      # overwrite the repo that is set in the parent
      @repo      = ::Stickler::Repository::Local.new( opts[:repo_root] )
    end

  end
end
