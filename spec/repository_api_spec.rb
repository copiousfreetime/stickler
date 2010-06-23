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
  end

  Stickler::Repository::Api.methods.each do |method|
    it "raises an error when calling unimplmented method #{method}" do
      lambda { @bad.send( method ) }.should raise_error( NotImplementedError, /\APlease implement .*##{method}\Z/ )
    end
  end
end
