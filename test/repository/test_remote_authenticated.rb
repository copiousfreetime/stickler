require 'test_stickler'
require 'stickler_test_server'
require 'repository/test_api_behavior'

module Stickler
  class AuthenticatedRemoteRepositoryTest < Test
    include RepositoryApiBehaviorTests

    attr_reader :repo

    def setup
      super
      @repo_uri = "http://stickler:secret@localhost:6789/"
      @repo     = ::Stickler::Repository::Remote.new( @repo_uri )
      @server   = SticklerTestServer.new( test_dir , "auth_repo.ru" )
      @server.start
    end

    def teardown 
      super
      @server.stop
    end

    def test_raising_authentication_denied
      repo = ::Stickler::Repository::Remote.new( "http://localhost:6789/")
      assert_raises( ::Stickler::Repository::Error ) do
        repo.get( @foo_spec )
      end
    end

    def test_authenticates_a_connection
      repo.push( @foo_gem_local_path )
      data = repo.get( @foo_spec )
      sha1 = Digest::SHA1.hexdigest( data )
      assert_equal @foo_digest, sha1
    end
  end
end

