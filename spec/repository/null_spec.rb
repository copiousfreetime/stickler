require File.expand_path( File.join( File.dirname(__FILE__), "..", "spec_helper.rb" ) )
require File.expand_path( File.join( File.dirname(__FILE__), "api_behavior.rb" ) )

require 'stickler/repository/null'

describe ::Stickler::Repository::Null do

  before do
    @repo = ::Stickler::Repository::Null.new
  end

  it "sets the repo_root to the class name" do
    @repo.repo_root.should == "Stickler::Repository::Null"
  end

  it_should_behave_like 'includes Repository::Api'
end
