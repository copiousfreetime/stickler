require File.expand_path( File.join( File.dirname(__FILE__), "..", "spec_helper.rb" ) )
require File.expand_path( File.join( File.dirname(__FILE__), "modern_gem_server_behavior.rb" ) )

require 'stickler/middleware/index'
require 'stickler/middleware/compression'

describe Stickler::Middleware::Index do
  def app
    ::Rack::Builder.new do
      use ::Stickler::Middleware::Compression
      use ::Stickler::Middleware::Index
      run ::Sinatra::Base
    end
  end

  before do
    @gem_dir = File.expand_path( File.join( File.dirname( __FILE__ ), "tmp" ) )
    FileUtils.mkdir_p( File.join( @gem_dir, "specifications" ))
  end

  after do
    FileUtils.rm_rf( @gem_dir )
  end

  it_should_behave_like "modern gem server indexes"
end
