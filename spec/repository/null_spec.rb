require 'spec_helper'
require 'repository/api_behavior'
describe ::Stickler::Repository::Null do

  before do
    @repo = ::Stickler::Repository::Null.new
  end

  it "sets the root_dir to the class name" do
    @repo.root_dir.should == "Stickler::Repository::Null"
  end

  it_should_behave_like 'includes Repository::Api'
end
