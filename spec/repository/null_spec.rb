require File.expand_path( File.join( File.dirname(__FILE__), "..", "spec_helper.rb" ) )
require File.expand_path( File.join( File.dirname(__FILE__), "api_behavior.rb" ) )

require 'stickler/repository/null'

describe ::Stickler::Repository::Null do

  before do
    @repo = ::Stickler::Repository::Null.new
  end

  it "sets the root_dir to the class name" do
    @repo.root_dir.should == "Stickler::Repository::Null"
  end

  it_should_behave_like 'includes Repository::Api'
end
