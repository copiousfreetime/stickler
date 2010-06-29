require File.expand_path( File.join( File.dirname(__FILE__), "..", "spec_helper.rb" ) )
require 'rubygems/server'

shared_examples_for "common gem server before after" do

  before do
    @webrick_spec_dir     = File.join( @webrick_gem_dir, "specifications" )

    @webrick           = ::Gem::Server.new(@webrick_gem_dir,4567,false)
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
      verify_webrick[:body]         = @webrick_response.body
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
        :body_length =>     last_response.body.length,
        :body =>            last_response.body
      }.should == verify_webrick
    else
      puts "webrick: #{verify_webrick[:body]}"
      #puts "sinatra: #{last_response.body}"
      last_response.status.should == verify_webrick[:status]
    end

  end


end
