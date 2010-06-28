require 'spec'
require 'rack/test'

Spec::Runner.configure do |config|
  config.include Rack::Test::Methods

  config.before( :each ) do
    @spec_dir           = File.expand_path( File.dirname( __FILE__ ) )
    @gem_root           = File.join( @spec_dir, 'data' )
    @specifications_dir = File.join( @gem_root, "specifications" )
    @gems_dir           = File.join( @gem_root, "gems" )
  end


end


