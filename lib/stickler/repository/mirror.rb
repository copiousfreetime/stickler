require 'stickler/repository'
require 'stickler/repository/remote'
require 'stickler/repository/local'
require 'forwardable'

module Stickler::Repository
  #
  # A Mirror mirrors gems in a Repository::Remote to a Repository::Local
  # All of the Repository::Api methods are delegated to the Local instance
  # and a new method #mirror() is added to pull gems from a Remote location 
  # and store in the Local instance
  #
  class Mirror
    class ConflictError < ::Stickler::Repository::Error ; end
    class NotFoundError < ::Stickler::Repository::Error ; end

    extend Forwardable

    def initialize( root_dir )
      @local_repo = ::Stickler::Repository::Local.new( root_dir )
      @remote_repos = {}
    end
    def_delegators :@local_repo, :uri, :gems_uri, :uri_for_gem, :search_for, 
                                 :push, :delete, :get, :open, 
                                 :specs, :latest_specs, :root_dir,
                                 :last_modified_time, :full_path_to_gem,
                                 :full_path_to_specification

    #
    # :call-seq:
    #   repo.mirror( spec, host = "rubygems.org" ) -> SpecLite
    #
    # Mirror the gem described by spec on the +host+.  If no +host+
    # is given, it is assumed to be http://rubygems.org/.
    #
    def mirror( host, spec )
      specs = @local_repo.search_for( spec )
      raise ConflictError, "gem #{spec.full_name} already exists" unless specs.empty?

      repo = remote_repo_for( host )
      repo.open( spec ) do |io|
        @local_repo.add( io )
      end
      raise NotFoundError, "Unable to find gem #{spec.full_name} on #{host}" unless @local_repo.gem_file_exist?( spec )
      return spec 
    end

    def remote_repo_for( host )
      @remote_repos[host] ||= ::Stickler::Repository::Remote.new( host, :debug => true )
    end
  end
end
