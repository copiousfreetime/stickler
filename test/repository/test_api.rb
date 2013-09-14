require 'test_stickler'
require 'digest/sha1'

module Stickler
  module RepositoryApiTests
    def test_implements_all_the_api_methods
      Stickler::Repository::Api.api_methods.each do |method|
        assert_respond_to repo, method
      end
    end
  end

  # Stub class for testing
  module Repository
    class Stub
      include Stickler::Repository::Api
    end
  end

  class RepositoryApiModuleTest < Test
    include RepositoryApiTests

    def repo
      @repo ||= Stickler::Repository::Stub.new
    end

    def setup
      @spec = Stickler::SpecLite.new( "foo", "1.0.0" )
    end

    def test_raising_error_on_unimplemented_methods
      %w[ uri gems_uri ].each do |method|
        assert_raises( NotImplementedError ) { repo.send( method ) }
      end
    end

    def test_raising_error_on_unimplemented_methods_taking_a_spec
      %w[ uri_for_gem search_for delete yank get open ].each do |method|
        assert_raises( NotImplementedError ) { repo.send( method, @spec ) }
      end
    end

    def test_raising_error_on_implemented_methods_taking_an_object
      %w[ push ].each do |method|
        assert_raises( NotImplementedError ) { repo.send( method, Object.new ) }
      end
    end
  end
end
