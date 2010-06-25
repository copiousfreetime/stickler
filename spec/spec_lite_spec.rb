require File.expand_path( File.join( File.dirname(__FILE__), "spec_helper.rb" ) )

require 'stickler/spec_lite'

describe Stickler::SpecLite do
  before do
    @specs = {
      :ruby => Stickler::SpecLite.new( 'foo', '0.4.2' ),
      :win  => Stickler::SpecLite.new( 'bar', '1.0.1', "x86-mswin32" )
    }
  end

  it "defaults to ruby platform" do
    @specs[:ruby].platform.should == Gem::Platform::RUBY
  end

  { [:ruby, 'file_name']      => "foo-0.4.2.gem",
    [:ruby, 'spec_file_name'] => "foo-0.4.2.gemspec" ,
    [:win , 'file_name']      => "bar-1.0.1-x86-mswin32.gem",
    [:win , 'spec_file_name'] => "bar-1.0.1-x86-mswin32.gemspec",
  }.each do |params, result|
    platform, method = *params
    it "on a #{platform} gem ##{method} is #{result}" do
      @specs[platform].send( method ).should == result
    end
  end

  it "has an array format" do
    @specs[:win].to_a.should == [ 'bar', '1.0.1', 'x86-mswin32' ]
  end

  it "returns false when compared to something that does not resond to :name, :version or :platform" do
    x = @specs[:ruby] =~ Object.new
    x.should == false
  end

  it "can compare against anything that responds to :name, :version and :platform" do
    class OSpec
      attr_accessor :name
      attr_accessor :version
      attr_accessor :platform
    end

    o = OSpec.new
    o.name = @specs[:ruby].name
    o.version = @specs[:ruby].version
    o.platform = @specs[:ruby].platform
    r = @specs[:ruby] =~ o
    r.should == true
  end
end
