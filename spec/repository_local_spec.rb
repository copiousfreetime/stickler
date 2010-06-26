require File.expand_path( File.join( File.dirname(__FILE__), "spec_helper.rb" ) )
require File.expand_path( File.join( File.dirname(__FILE__), "repository_api_behavior.rb" ) )

require 'stickler/repository/local'

describe ::Stickler::Repository::Local do

  before do
    @repo_dir = File.join( @spec_dir, "tmp" )
    @repo = ::Stickler::Repository::Local.new( @repo_dir )
  end

  after( :each ) do
    FileUtils.rm_rf( @repo_dir )
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
    @repo.specs.size.should == 2
  end

  it_should_behave_like 'includes Repository::Api'
  it_should_behave_like 'implements Repository::Api'
end

