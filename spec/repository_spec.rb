require File.expand_path(File.join(File.dirname(__FILE__),"spec_helper.rb"))
require 'stickler'

describe Stickler::Repository do

  before( :each ) do
    @top_dir = File.join( "/tmp/stickler" )
    @repo = Stickler::Repository.new( 'directory' => @top_dir )
    Stickler.silent { @repo.setup }
  end

  after( :each ) do
    FileUtils.rm_rf( @top_dir )
  end


  describe "#setup" do
    %w[ gems log specifications dist ].each do |sub_dir|
      it "creates #{sub_dir} directory" do
        new_dir = File.join( @top_dir , sub_dir )
        File.directory?( new_dir ).should == true
      end
    end

    it "setup creates a default stickler.yml file" do
      s_yml = File.join( @top_dir, 'stickler.yml' )
      s = YAML.load_file( s_yml )
      s['upstream_sources'].size.should == 1
      s['upstream_sources'].first.should == "http://gems.rubyforge.org/"
    end
  end

  describe "validity checks" do
    %w[ gems log specifications dist ].each do |sub_dir|
      it "raises error if #{sub_dir} is missing" do
        FileUtils.rmdir( File.join( @top_dir, sub_dir ) )
        lambda { Stickler.silent { @repo.valid! } }.should raise_error( Stickler::Repository::Error ) 
      end

      it "return false if #{sub_dir} is missing" do
        FileUtils.rmdir( File.join( @top_dir, sub_dir ) )
        Stickler.silent{ @repo.should_not be_valid }
      end
    end

    it "can create a valid directory system" do
      @repo.should be_valid
    end
  end

  it "creates a configuration" do
    @repo.configuration['upstream_sources'].size.should == 1
    @repo.configuration['upstream_sources'].first.should == "http://gems.rubyforge.org/"
  end
end
