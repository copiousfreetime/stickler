require 'test_stickler'
require 'digest/sha1'
require 'repository/test_api'

module Stickler
  module RepositoryApiBehaviorTests
    include RepositoryApiTests
    def setup
      super
      @foo_gem_local_path = File.join( gems_dir, "foo-1.0.0.gem" )
      @baz_gem_local_path = File.join( gems_dir, "baz-3.1.4-java.gem" )
      @foo_spec           = Stickler::SpecLite.new( 'foo', '1.0.0' )
      @baz_java_spec      = Stickler::SpecLite.new( 'baz', '3.1.4', 'java')
      assert File.readable?( @foo_gem_local_path ), "#{@foo_gem_local_path} is missing"
      assert File.readable?( @baz_gem_local_path ), "#{@baz_gem_local_path} is missing"
      @foo_digest         = Digest::SHA1.hexdigest( IO.read( @foo_gem_local_path ) )
      @missing_spec       = Stickler::SpecLite.new( "does_not_exist", "0.1.0" )
    end

    #####
    # URI
    #####

    def test_uri
      result = repo.uri
      assert_includes [ ::URI, ::Addressable::URI ], result.class
    end

    def test_gems_uri
      result = repo.gems_uri
      assert_includes [ ::URI, ::Addressable::URI ], result.class
    end

    def test_uri_for_gem
      repo.push( @foo_gem_local_path )
      result = repo.uri_for_gem( @foo_spec )
      assert_includes [ ::URI, ::Addressable::URI ], result.class
      assert_nil repo.uri_for_gem( @missing_spec )
    end

    #######
    # Push
    #######

    def test_pushes_a_gem_file
      repo.push( @foo_gem_local_path )
      result = repo.search_for( Stickler::SpecLite.new( "foo", "1.0.0" ) )
      assert_instance_of Array, result
      assert_equal 1, result.size
    end

    def test_raising_error_when_pushing_already_existing_gem
      repo.push( @foo_gem_local_path )
      assert_raises_kind_of( Stickler::Repository::Error ) do 
        repo.push( @foo_gem_local_path )
      end
    end

    def test_raising_error_when_pushing_to_not_existent_server
      not_existent_repo = ::Stickler::Repository::Remote.new("http://notexistent:6789/")
      assert_raises_kind_of( Stickler::Repository::Error ) do
        not_existent_repo.push( @foo_gem_local_path )
      end
    end

    ########
    # Delete
    ########

    def test_delete_existing_gem
      assert_empty repo.search_for( @foo_spec )
      repo.push( @foo_gem_local_path )
      
      assert_equal 1, repo.search_for( @foo_spec ).size

      assert repo.delete( @foo_spec )
      assert_empty repo.search_for( @foo_spec )
    end

    def test_delete_non_existing_gem
      assert_empty repo.search_for( @foo_spec )
      refute repo.delete( @foo_spec )
    end

    ######
    # yank
    ######

    def test_yank_returns_the_uri_of_the_gem
      assert_empty repo.search_for( @foo_spec )
      repo.push( @foo_gem_local_path )
      @response_uri = repo.yank( @foo_spec )
      assert_includes [ ::URI, ::Addressable::URI ], @response_uri.class
    end

    def test_yank_works_with_nondefault_platform
      assert_empty repo.search_for( @baz_java_spec )
      repo.push( @baz_gem_local_path )
      @response_uri = repo.yank( @baz_java_spec )
      assert_includes [ ::URI, ::Addressable::URI ], @response_uri.class
    end

    def test_yank_returns_nil_for_non_existent_gem
      assert_nil repo.yank( @missing_spec )
    end

    def test_yanked_gem_does_not_appear_in_search
      assert_empty repo.search_for( @foo_spec )
      repo.push( @foo_gem_local_path )
      @response_uri = repo.yank( @foo_spec )
      assert_empty repo.search_for( @foo_spec )
    end

    def test_yanked_gem_does_still_have_a_uri
      assert_empty repo.search_for( @foo_spec )
      repo.push( @foo_gem_local_path )
      @response_uri = repo.yank( @foo_spec )
      assert_equal @response_uri, repo.uri_for_gem( @foo_spec )
    end

    def test_yanked_gem_may_still_be_retrieved
      assert_empty repo.search_for( @foo_spec )
      repo.push( @foo_gem_local_path )
      data = repo.get( @foo_spec )
      sha1 = Digest::SHA1.hexdigest( data )
      assert_equal @foo_digest, sha1
    end

    ########
    # unyank 
    ########
    
    def test_unyank_returns_nil_for_non_existent_gem
      assert_empty repo.search_for( @foo_spec )
      repo.push( @foo_gem_local_path )
      non_existing_gem = @missing_spec
      assert_nil repo.unyank( non_existing_gem )
    end

    def test_unyank_works_with_nondefault_platform
      assert_empty repo.search_for( @baz_java_spec )
      repo.push( @baz_gem_local_path )
      repo.yank( @baz_java_spec )
      assert_empty repo.search_for( @baz_java_spec )
      repo.unyank( @baz_java_spec )
      assert_equal 1, repo.search_for( @baz_java_spec ).size
    end

    # Do we even care about this?
    def test_unyank_returns_nil_for_not_yet_yanked_gem
      assert_empty repo.search_for( @foo_spec )
      repo.push( @foo_gem_local_path )
      assert_equal 1, repo.search_for( @foo_spec ).size
      assert_nil repo.unyank( @foo_spec )
    end

    def test_unyank_returns_true_on_success
      assert_empty repo.search_for( @foo_spec )
      repo.push( @foo_gem_local_path )
      repo.yank( @foo_spec )
      assert repo.unyank( @foo_spec ), "Expected true"
    end

    def test_unyank_returns_gem_to_searchability
      assert_empty repo.search_for( @foo_spec )
      repo.push( @foo_gem_local_path )
      repo.yank( @foo_spec )
      repo.unyank( @foo_spec )
      assert_equal 1, repo.search_for( @foo_spec ).size
    end

    ############
    # Search For
    ############
    
    def test_search_for_returns_found_items 
      repo.push( @foo_gem_local_path )
      refute_empty repo.search_for( @foo_spec )
    end

    def test_search_for_returns_empty_array_when_nothing_found
      assert_empty repo.search_for( @missing_spec )
    end


    #####
    # GET
    #####
    
    def test_get_returns_the_bytes_of_a_gem_that_exists
      repo.push( @foo_gem_local_path )
      data = repo.get( @foo_spec )
      sha1 = Digest::SHA1.hexdigest( data )
      assert_equal @foo_digest, sha1
    end

    def test_get_returns_nil_for_non_existent_gem
      assert_nil repo.get( @missing_spec )
    end

    ######
    # open
    ######
    
    def test_open_reads_a_gem_via_the_returned_output_stream
      repo.push( @foo_gem_local_path )
      io = repo.open( @foo_spec )
      sha1 = Digest::SHA1.hexdigest( io.read )
      assert_equal @foo_digest, sha1
    end

    def test_open_may_be_called_with_a_block
      repo.push( @foo_gem_local_path )
      sha1 = Digest::SHA1.new
      repo.open( @foo_spec ) do |io|
        sha1 << io.read
      end
      assert_equal @foo_digest, sha1.hexdigest
    end

    def test_open_returns_nil_for_non_existent_gem
      assert_nil repo.open( @missing_spec )
    end

    def test_open_does_not_call_block_for_non_existent_gem
      called = false
      repo.open( @missing_spec ) do |io|
        called = true
      end
      refute called
    end
  end
end
