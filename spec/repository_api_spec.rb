require File.expand_path( File.join( File.dirname(__FILE__), "spec_helper.rb" ) )

require 'stickler/repository/api'
module Stickler::Repository
  class Stub
    include Stickler::Repository::Api
  end
end

describe Stickler::Repository::Api do
  before do
    @stub = Stickler::Repository::Stub.new
    @spec = Stickler::SpecLite.new( "foo", "1.0.0" )
  end

  %w[ uri gems_uri specifications_uri source_index ].each do |method|
    it "raises an error when calling unimplmented method #{method}" do
      lambda { @stub.send( method ) }.should raise_error( NotImplementedError, /\APlease implement .*##{method}\Z/ )
    end
  end

  %w[ uri_for_gem uri_for_specification search_for delete yank get open ].each do |method|
    it "raises an error when calling unimplmented method #{method} taking a spec" do
      lambda { @stub.send( method, @spec ) }.should raise_error( NotImplementedError, /\APlease implement .*##{method}\Z/ )
    end
  end

  %w[ add push ].each do |method|
    it "raises an error when calling unimplmented method #{method} taking some other object" do
      lambda { @stub.send( method, @spec ) }.should raise_error( NotImplementedError, /\APlease implement .*##{method}\Z/ )
    end
  end

  describe "responds to all the api methods" do
    Stickler::Repository::Api.api_methods.each do |method|
      it "responds to ##{method}" do
        @stub.respond_to?( method ).should == true
      end
    end
  end
end
