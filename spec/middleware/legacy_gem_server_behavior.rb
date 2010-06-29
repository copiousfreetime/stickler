require File.expand_path( File.join( File.dirname(__FILE__), "..", "spec_helper.rb" ) )
require File.expand_path( File.join( File.dirname(__FILE__), "common_gem_server_helpers.rb" ) )

require 'rubygems/server'

shared_examples_for "legacy gem server indexes" do

  it_should_behave_like "common gem server before after" 

  LEGACY_URLS = [
    "/yaml",
    "/yam.Z",
    "/Marshal.#{Gem.marshal_version}",
    "/Marshal.#{Gem.marshal_version}.Z",
    "/quick/index",
    "/quick/index.rz",
    "/quick/latest_index",
    "/quick/latest_index.rz",
    "/quick/foo-1.0.0.gemspec.rz",
    "/quick/bar-1.0.0.gemspec.rz",
    "/quick/does-not-exist-1.2.0.gemspec.rz"
  ]

  LEGACY_URLS.each do |url|
    it "serves a legacy gem server index item from #{url}" do
      should_match_webrick_behavior url
    end
  end
end


