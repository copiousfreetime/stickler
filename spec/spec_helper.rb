require 'spec'
require 'rack/test'

Spec::Runner.configure do |config|
  config.include Rack::Test::Methods

  @gem_root     = File.expand_path( File.join( File.dirname(__FILE__), "data" ) )
  @gem_spec_dir = File.join( @gem_dir, "specifications" )
end


