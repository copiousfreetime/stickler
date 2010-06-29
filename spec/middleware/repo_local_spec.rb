require File.expand_path( File.join( File.dirname(__FILE__), "..", "spec_helper.rb" ) )
require File.expand_path( File.join( File.dirname(__FILE__), "modern_gem_server_behavior.rb" ) )
require File.expand_path( File.join( File.dirname(__FILE__), "legacy_gem_server_behavior.rb" ) )

require 'stickler/middleware/local'
require 'stickler/middleware/compression'

describe ::Stickler::Middleware::Local do
  def app
    gem_dir = @gem_dir
    ::Rack::Builder.new do
      use ::Stickler::Middleware::Compression
      use ::Stickler::Middleware::RepoLocal, :repo_root => gem_dir
      run ::Sinatra::Base
    end
  end

  before do
    @gem_dir      = File.join( @spec_dir, "data" )
  end

  it_should_behave_like "modern gem server indexes"
#  it_should_behave_like "legacy gem server indexes"

end    
