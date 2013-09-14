require 'test_stickler'
require 'stickler_test_server'
require 'repository/test_api_behavior'

module Stickler
  class RemoteRepositoryTest < Test
    include RepositoryApiBehaviorTests

    attr_reader :repo

    def setup 
      super
      @repo_uri = "http://localhost:6789/"
      @repo     = ::Stickler::Repository::Remote.new( @repo_uri, :debug => true )
      @server   = SticklerTestServer.new( test_dir, "gemcutter_repo.ru" )
      @server.start
    end

    def teardown 
      super
      @server.stop
    end
  end

end

