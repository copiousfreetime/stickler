require File.expand_path( "../spec_helper",File.dirname(__FILE__) )

require 'stickler/middleware/local'
require 'stickler/middleware/compression'

describe Stickler::Middleware::Local do

  include IndexSpecHelpers
  include Rack::Test::Methods

  def app
    repo_root = @idx_spec_datadir
    ::Rack::Builder.new do
      use ::Stickler::Middleware::Compression
      use ::Stickler::Middleware::Local, :repo_root => repo_root
      run ::Sinatra::Base
    end
  end

  describe "When serving a modern index" do
    before( :all ) do 
      mirror_spec_gemdir
      make_modern_index
    end

    after( :all ) do
      destroy_scratch_dir
    end

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
    ].each do |path|
      it "should return the same bytes as Gem::Indexer for '#{path}'" do
        response = get( path )
        validate_contents( response.body,
                           IO.read( File.join(@scratch_datadir, path) ),
                           response.content_type )
      end
    end
  end

  describe "When serving a legacy index" do
     before( :all ) do 
      mirror_spec_gemdir
      make_legacy_index
    end

    after( :all ) do
      destroy_scratch_dir
    end

    [
      "/Marshal.#{Gem.marshal_version}",
      "/Marshal.#{Gem.marshal_version}.Z",
    ].each do |path|
      it "should return the same bytes as Gem::Indexer for '#{path}'" do
        pending
        response = get( path )
        validate_contents( response.body,
                           IO.read( File.join(@scratch_datadir, path) ),
                           response.content_type )
      end
    end
  end
end
