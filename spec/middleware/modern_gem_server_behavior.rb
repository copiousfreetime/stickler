require File.expand_path( File.join( File.dirname(__FILE__), "..", "spec_helper.rb" ) )
require File.expand_path( File.join( File.dirname(__FILE__), "common_gem_server_helpers.rb" ) )

shared_examples_for "modern gem server indexes" do

  it_should_behave_like "common gem server before after"

  MODERN_URLS = [
  "/specs.#{Gem.marshal_version}",
  "/specs.#{Gem.marshal_version}.gz",
  "/latest_specs.#{Gem.marshal_version}",
  "/latest_specs.#{Gem.marshal_version}.gz",
  "/quick/Marshal.#{Gem.marshal_version}/foo-1.0.0.gemspec.rz",
  "/quick/Marshal.#{Gem.marshal_version}/bar-1.0.0.gemspec.rz",
  ]

  MODERN_URLS.each do |url|
    it "serves a modern gem server index item from #{url}" do
      should_match_webrick_behavior url
    end
  end
end
