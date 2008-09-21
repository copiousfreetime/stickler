require File.expand_path(File.join(File.dirname(__FILE__),"spec_helper.rb"))
require 'stickler/version'

describe "Stickler::Version" do
  it "should have a version string" do
    Stickler::Version.to_s.should =~ /\d+\.\d+\.\d+/
    Stickler::VERSION.should =~ /\d+\.\d+\.\d+/
  end

  describe "has the version accessible as a hash" do
    [ :major, :minor, :build ].each do |part|
      it "#{part}" do
        Stickler::Version.to_hash[ part ].to_s.should =~ /\d+/
      end
    end
  end
end
