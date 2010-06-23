require File.expand_path( File.join( File.dirname(__FILE__), "spec_helper.rb" ) )

require 'stickler/repository/api'
module Stickler::Repository
  class Bad
    include Stickler::Repository::Api
  end
end

describe Stickler::Repository::Api do
  before do
    @bad = Stickler::Repository::Bad.new
    @spec = Stickler::SpecLite.new( "foo", "1.0.0" )
  end

  %w[ uri gems_uri specifications_uri source_index ].each do |method|
    it "raises an error when calling unimplmented method #{method}" do
      lambda { @bad.send( method ) }.should raise_error( NotImplementedError, /\APlease implement .*##{method}\Z/ )
    end
  end

  %w[ uri_for_gem uri_for_specification search_for delete yank get open ].each do |method|
    it "raises an error when calling unimplmented method #{method} taking a spec" do
      lambda { @bad.send( method, @spec ) }.should raise_error( NotImplementedError, /\APlease implement .*##{method}\Z/ )
    end
  end

  %w[ add push ].each do |method|
    it "raises an error when calling unimplmented method #{method} taking some other object" do
      lambda { @bad.send( method, @spec ) }.should raise_error( NotImplementedError, /\APlease implement .*##{method}\Z/ )
    end
  end
end
