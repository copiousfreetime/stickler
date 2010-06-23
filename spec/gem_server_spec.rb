require File.expand_path( File.join( File.dirname(__FILE__), "spec_helper.rb" ) )

require 'stickler/web'
require 'rubygems/source_index'
require 'rubygems/server'

describe 'Stickler::Web' do
  before do 
    @gem_dir      = File.expand_path( File.join( File.dirname(__FILE__), "data" ) )
    @spec_dir     = File.join( @gem_dir, "specifications" )

    @webrick           = ::Gem::Server.new(@gem_dir,4567,false)
    @underlying_server = @webrick.instance_variable_get("@server")
    @webrick_thread    = Thread.new( @webrick ) do |webrick| 
      webrick.run
    end
    @webrick_request  = WEBrick::HTTPRequest.new :Logger => nil
    @webrick_response = WEBrick::HTTPResponse.new :HTTPVersion => '1.0'
  end

  after do
    @underlying_server.shutdown
    @webrick_thread.kill
  end

  def app
    gem_dir = @gem_dir
    ::Rack::Builder.new do
      use ::Stickler::GemServerDeflater
      use ::Stickler::GemServer, :gem_path => gem_dir
      run ::Sinatra::Base
    end
  end

  #
  # pulled and modified from sinatra-rubygems
  # http://github.com/jnewland/sinatra-rubygems
  # 
  def should_match_webrick_behavior(url)

    #webrick
    data = StringIO.new "GET #{url} HTTP/1.0\r\n\r\n"
    @webrick_request.parse data
    verify_webrick = {}
    begin
      @underlying_server.service( @webrick_request, @webrick_response)
      verify_webrick[:status]       = @webrick_response.status
      verify_webrick[:content_type] = @webrick_response['Content-Type']
      verify_webrick[:body_length]  = @webrick_response.body.length
    rescue WEBrick::HTTPStatus::NotFound
      verify_webrick = {
        :status       => 404,
        :content_type => 'text/html',
        :body_length  => "446"
      }
    end

    #sinatra
    get url

    #verify
    if 200 == last_response.status and 200 == verify_webrick[:status] then
      {
        :status =>          last_response.status,
        :content_type =>    last_response['Content-Type'],
        :body_length =>     last_response.body.length 
      }.should == verify_webrick
    else
      last_response.status.should == verify_webrick[:status]
    end

  end

  [ "/yaml",
    "/yam.Z",
    "/Marshal.#{Gem.marshal_version}",
    "/Marshal.#{Gem.marshal_version}.Z",
    "/specs.#{Gem.marshal_version}",
    "/specs.#{Gem.marshal_version}.gz",
    "/latest_specs.#{Gem.marshal_version}",
    "/latest_specs.#{Gem.marshal_version}.gz",
    "/quick/index",
    "/quick/index.rz",
    "/quick/latest_index",
    "/quick/latest_index.rz",
    "/quick/Marshal.#{Gem.marshal_version}/foo-1.0.0.gemspec.rz",
    "/quick/foo-1.0.0.gemspec.rz",
    "/quick/Marshal.#{Gem.marshal_version}/bar-1.0.0.gemspec.rz",
    "/quick/bar-1.0.0.gemspec.rz",
    "/quick/does-not-exist-1.2.0.gemspec.rz"
  ].each do |url|

      it "serves indicies from #{url}" do
        should_match_webrick_behavior url
      end

  end
end    
