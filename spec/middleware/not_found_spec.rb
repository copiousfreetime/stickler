require 'spec_helper'

describe ::Stickler::Middleware::NotFound do
  include Rack::Test::Methods
  def app
    ::Stickler::Middleware::NotFound.new
  end

  before do
    get "/"
  end

  it "should respond to a 404 on everything"  do
    get '/'
    last_response.status.should == 404
  end

  it "should return a 'text/html' page" do
    last_response.content_type.should == 'text/html'
  end

  it "should say to go look somewhere else" do
    last_response.body.should =~ /Not Found/m
  end
end
