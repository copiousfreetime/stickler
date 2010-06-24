require File.expand_path( File.join( File.dirname(__FILE__), "spec_helper.rb" ) )
require File.expand_path( File.join( File.dirname(__FILE__), "repository_api_behavior.rb" ) )

require 'stickler/repository/local'

describe Stickler::Repository::Local do

  before do
    @top_dir = File.join( "/tmp/stickler" )
    @repo = Stickler::Repository::Local.new( @top_dir )
  end

  after( :each ) do
    FileUtils.rm_rf( @top_dir )
  end

  %w[ gems specifications ].each do |sub_dir|
    it "creates #{sub_dir} directory" do
      new_dir = File.join( @top_dir , sub_dir ) + File::SEPARATOR
      File.directory?( new_dir ).should == true
      @repo.send( "#{sub_dir}_dir" ).should == new_dir
    end

  end

  it_should_behave_like 'includes Repository::Api'
  it_should_behave_like 'implements Repository::Api'
end

