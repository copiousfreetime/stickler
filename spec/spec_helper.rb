if RUBY_VERSION >= '1.9.2' then
  require 'simplecov'
  SimpleCov.start if ENV['COVERAGE']
end

require "rspec/autorun"
require 'stickler'
require 'index_spec_helpers'


RSpec.configure do |config|

  config.before( :each ) do
    @spec_dir           = File.expand_path( File.dirname( __FILE__ ) )
    @gem_root           = File.join( @spec_dir, 'data' )
    @specifications_dir = File.join( @gem_root, "specifications" )
    @gems_dir           = File.join( @gem_root, "gems" )
  end

  config.after( :each ) do
    ::Stickler::Repository::Local.purge
  end

end
