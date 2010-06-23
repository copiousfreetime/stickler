require 'spec'
require 'rack/test'

Spec::Runner.configure do |config|
  config.include Rack::Test::Methods

  config.before( :each ) do
    @gem_root           = File.expand_path( File.join( File.dirname(__FILE__), "data" ) )
    @specifications_dir = File.join( @gem_root, "specifications" )
    @gems_dir           = File.join( @gem_root, "gems" )
  end
end


