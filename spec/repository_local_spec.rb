require File.expand_path( File.join( File.dirname(__FILE__), "spec_helper.rb" ) )
require File.expand_path( File.join( File.dirname(__FILE__), "repository_api_behavior.rb" ) )

require 'stickler/repository/local'

describe Stickler::Repository::Local do

  before do
    @top_dir = File.join( "/tmp/stickler" )
    @repo = Stickler::Repository::Local.new( @top_dir )
    @foo_path = File.join( @gems_dir, "foo-1.0.0.gem" )
  end

  after( :each ) do
    FileUtils.rm_rf( @top_dir )
  end

  %w[ gems specifications ].each do |sub_dir|
    it "creates #{sub_dir} directory" do
      new_dir = File.join( @top_dir , sub_dir )
      File.directory?( new_dir ).should == true
    end
  end

  #it_should_behave_like 'includes Repository::Api'
  it_should_behave_like 'implements Repository::Api'
end

