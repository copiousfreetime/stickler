require File.expand_path( File.join( File.dirname(__FILE__), "spec_helper.rb" ) )
require File.expand_path( File.join( File.dirname(__FILE__), "repository_api_behavior.rb" ) )

require 'stickler/repository/api'
module Stickler::Repository
  class Stub
    include Stickler::Repository::Api
  end
end

describe Stickler::Repository::Api do
  before do
    @repo = Stickler::Repository::Stub.new
    @spec = Stickler::SpecLite.new( "foo", "1.0.0" )
  end

  %w[ uri gems_uri specifications_uri source_index ].each do |method|
    it "raises an error when calling unimplmented method #{method}" do
      lambda { @repo.send( method ) }.should raise_error( NotImplementedError, /\APlease implement .*##{method}\Z/ )
    end
  end

  %w[ uri_for_gem uri_for_specification search_for delete yank get open ].each do |method|
    it "raises an error when calling unimplmented method #{method} taking a spec" do
      lambda { @repo.send( method, @spec ) }.should raise_error( NotImplementedError, /\APlease implement .*##{method}\Z/ )
    end
  end

  %w[ add push ].each do |method|
    it "raises an error when calling unimplmented method #{method} taking some other object" do
      lambda { @repo.send( method, @spec ) }.should raise_error( NotImplementedError, /\APlease implement .*##{method}\Z/ )
    end
  end

  it_should_behave_like 'includes Repository::Api'
end


