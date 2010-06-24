require File.expand_path( File.join( File.dirname(__FILE__), "spec_helper.rb" ) )
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

  it "pushes a gem from a .gem file" do
    @repo.push( @foo_path )
    @repo.search_for( Stickler::SpecLite.new( "foo", "1.0.0" ) )
  end

  it "raises an error when pushing a gem if the gem already exists" do
    @repo.push( @foo_path )
    lambda { @repo.push( @foo_path ) }.should raise_error( Stickler::Repository::Error, /gem foo-1.0.0 already exists/ )
  end

  describe "responds to all the api methods" do
    Stickler::Repository::Api.api_methods.each do |method|
      it "responds to ##{method}" do
        @repo.respond_to?( method ).should == true
      end
    end
  end
end

