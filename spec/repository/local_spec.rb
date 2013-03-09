require 'spec_helper'
require 'repository/api_behavior'

describe ::Stickler::Repository::Local do

  before( :each ) do
    @repos_dir = File.join( @spec_dir, "repos" )
    @repo_dir  = File.join( @repos_dir, "1" )
    @repo      = ::Stickler::Repository::Local.new( @repo_dir )
  end

  after( :each ) do
    ::Stickler::Repository::Local.purge
    FileUtils.rm_rf( @repos_dir )
  end

  %w[ gems specifications ].each do |sub_dir|
    it "creates #{sub_dir} directory" do
      new_dir = File.join( @repo_dir , sub_dir ) + File::SEPARATOR
      File.directory?( new_dir ).should == true
      @repo.send( "#{sub_dir}_dir" ).should == new_dir
    end

  end

  it "returns a list of all the specs in the repo" do
    Dir.glob( File.join( @gems_dir, "*.gem" ) ).each do |gem|
      @repo.push( gem )
    end
    @repo.specs.size.should == 5
  end

  it "two instances with the same repo dir are the same object" do
    repo2 = ::Stickler::Repository::Local.new( File.join(@repos_dir, '1') )
    repo2.object_id.should == @repo.object_id
    ::Stickler::Repository::Local.repos.size.should == 1
  end


  it "keeps track of all the repository instances" do
    repo2 = ::Stickler::Repository::Local.new( File.join(@repos_dir, "2" ) )
    repo3 = ::Stickler::Repository::Local.new( File.join(@repos_dir, "3" ) )
    ::Stickler::Repository::Local.repos.size.should == 3
  end

  it_should_behave_like 'includes Repository::Api'
  it_should_behave_like 'implements Repository::Api'
end

