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

  it "adds a gem from a .gem file" do
    @repo.add_gem_from_file( @foo_path )
    @repo.search_for( Stickler::SpecLite.new( "foo", "1.0.0" ) )
  end

  it "raises and error on adding a gem if the gem already exists" do
    @repo.add_gem_from_file( @foo_path )
    lambda { @repo.add_gem_from_file( @foo_path ) }.should raise_error( Stickler::Repository::Error, /gem foo-1.0.0 already exists/ )
  end
end

