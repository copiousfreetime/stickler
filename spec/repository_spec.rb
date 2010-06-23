require File.expand_path( File.join( File.dirname(__FILE__), "spec_helper.rb" ) )
require File.expand_path(File.join(File.dirname(__FILE__),"spec_helper.rb"))
require 'stickler'

describe Stickler::Repository do

  before( :each ) do
    @top_dir = File.join( "/tmp/stickler" )
    @repo = Stickler::Repository.new( 'directory' => @top_dir )
  end

  after( :each ) do
    FileUtils.rm_rf( @top_dir )
  end


  describe "#setup" do
    %w[ gems specifications ].each do |sub_dir|
      it "creates #{sub_dir} directory" do
        new_dir = File.join( @top_dir , sub_dir )
        File.directory?( new_dir ).should == true
      end
    end
  end

  describe "validity checks" do
    %w[ gems log specifications dist cache].each do |sub_dir|
      it "raises error if #{sub_dir} is missing" do
        FileUtils.rmdir( File.join( @top_dir, sub_dir ) )
        lambda { Stickler::Console.silent { @repo.valid! } }.should raise_error( Stickler::Repository::Error ) 
      end

      it "return false if #{sub_dir} is missing" do
        FileUtils.rmdir( File.join( @top_dir, sub_dir ) )
        Stickler::Console.silent{ @repo.should_not be_valid }
      end
    end

    it "can create a valid directory system" do
      @repo.should be_valid
    end
  end

  it "creates a configuration" do
    @repo.configuration['sources'].size.should == 1
    @repo.configuration['sources'].first.should == "http://gems.rubyforge.org/"
  end
end

