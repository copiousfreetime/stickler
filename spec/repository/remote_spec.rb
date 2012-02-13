require File.expand_path( File.join( File.dirname(__FILE__), "..", "spec_helper.rb" ) )
require File.expand_path( File.join( File.dirname(__FILE__), "api_behavior.rb" ) )

require 'stickler/repository/remote'

class SticklerTestServer
  def initialize( spec_dir, ru_file )
    @spec_dir = spec_dir
    @repo_uri = "http://localhost:6789/"
    @tmp_dir  = File.join( @spec_dir, "tmp" )
    FileUtils.mkdir_p( @tmp_dir )

    @pid_file = File.join( @tmp_dir , "rack.pid" )
    @ru_file  = File.expand_path( File.join( @spec_dir, "..", "examples", ru_file ) )
    @cmd = "rackup --port 6789 --pid #{@pid_file} --daemonize #{@ru_file}"
  end

  def start
    system @cmd
    tries = 0
    loop do
      begin
        Excon.get( @repo_uri + "specs.#{Gem.marshal_version}.gz" )
        #puts "rackup started with pid #{IO.read( @pid_file )}"
        break
      rescue => e
        tries += 1
        sleep tries * 0.1
      end
    end
  end

  def stop
    pid = IO.read( @pid_file ).to_i
    Process.kill( 'KILL', pid )
    #FileUtils.rm_rf( @tmp_dir, :verbose => true )
    FileUtils.rm_rf( @tmp_dir )
  end
end

describe Stickler::Repository::Remote do
  before do
    @repo_uri = "http://localhost:6789/"
    @repo     = ::Stickler::Repository::Remote.new( @repo_uri, :debug => true )
  end

  it_should_behave_like 'includes Repository::Api'

  describe "Using a live server" do
    before do
      @server = SticklerTestServer.new( @spec_dir, "gemcutter_repo.ru" )
      @server.start
    end

    after do
      @server.stop
    end

    it_should_behave_like 'implements Repository::Api'
  end

  describe "Using a live authenticated server" do
    before do
      @server = SticklerTestServer.new( @spec_dir, "auth_repo.ru" )
      @server.start
      @foo_gem_local_path = File.join( @gems_dir, "foo-1.0.0.gem" )
      @foo_spec           = Stickler::SpecLite.new( 'foo', '1.0.0' )
      @foo_digest         = Digest::SHA1.hexdigest( IO.read( @foo_gem_local_path ) )
    end

    after do
      @server.stop
    end

    it "should raise an an authentication denied error" do
      repo = ::Stickler::Repository::Remote.new( "http://localhost:6789/")
      lambda { repo.get( @foo_spec ) }.should raise_error( ::Stickler::Repository::Error, /Not authorized/ )
    end

    it "should connect with proper authentication" do
      repo = ::Stickler::Repository::Remote.new( "http://stickler:secret@localhost:6789/")
      data = repo.get( @foo_spec )
      sha1 = Digest::SHA1.hexdigest( data )
      sha1.should == @foo_digest
    end
  end
end

