require 'test_stickler'

module Stickler
  class MiddlewareLocalTest < Test
    include IndexTestHelpers
    include Rack::Test::Methods

    def app
      repo_root = @idx_test_datadir
      ::Rack::Builder.new do
        use ::Stickler::Middleware::Compression
        use ::Stickler::Middleware::Local, :repo_root => repo_root
        run ::Sinatra::Base
      end
    end
  end

  class MiddlewareLocalModernTest < MiddlewareLocalTest
    def setup
      mirror_spec_gemdir
      make_modern_index
    end

    def teardown
      destroy_scratch_dir
    end

    def test_returns_the_same_bytes_as_gem_indexer 
      [
        "/specs.#{Gem.marshal_version}",
        "/specs.#{Gem.marshal_version}.gz",
        "/latest_specs.#{Gem.marshal_version}",
        "/latest_specs.#{Gem.marshal_version}.gz",
        "/prerelease_specs.#{Gem.marshal_version}",
        "/prerelease_specs.#{Gem.marshal_version}.gz",
        "/quick/Marshal.#{Gem.marshal_version}/foo-1.0.0.gemspec.rz",
        "/quick/Marshal.#{Gem.marshal_version}/bar-1.0.0.gemspec.rz",
        "/quick/Marshal.#{Gem.marshal_version}/foo-2.0.0a.gemspec.rz",
        "/quick/Marshal.#{Gem.marshal_version}/baz-3.1.4-java.gemspec.rz",
        "/quick/Marshal.#{Gem.marshal_version}/baz-3.1.4.gemspec.rz",
      ].each do |path|
        response  = get( path )
        need, got = validate_contents( response.body,
                                       IO.read( File.join(@scratch_datadir, path) ),
                                       response.content_type )
        assert_equal need, got, "Match failure for #{path}"
      end
    end
  end

  class MiddlewareLocalLegacyTest < MiddlewareLocalTest
    def setup
      mirror_spec_gemdir
      make_legacy_index
    end

    def teardown
      destroy_scratch_dir
    end

    def test_returns_the_same_bytes_as_gem_indexer 
      [
        "/Marshal.#{Gem.marshal_version}",
        "/Marshal.#{Gem.marshal_version}.Z",
      ].each do |path|
        skip "Not testing legacy indexes at the moment"
        response  = get( path )
        need, got = validate_contents( response.body,
                                       IO.read( File.join(@scratch_datadir, path) ),
                                       response.content_type )
        assert_equal need, got, "Match failure for #{path}"
      end
    end
  end
end
