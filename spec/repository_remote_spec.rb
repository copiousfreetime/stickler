require File.expand_path( File.join( File.dirname(__FILE__), "spec_helper.rb" ) )
require File.expand_path( File.join( File.dirname(__FILE__), "repository_api_behavior.rb" ) )

require 'stickler/repository/remote'

describe Stickler::Repository::Remote do

  it_should_behave_like 'includes Repository::Api'

  describe "Using a live server" do
    before do
      @tmp_dir  = File.join( @spec_dir, "tmp" )
      %w[ gems specifications ].each { |s| FileUtils.mkdir_p( File.join( @tmp_dir, s ) ) }

      @repo_uri = "http://localhost:6789/"
      @repo     = ::Stickler::Repository::Remote.new( @repo_uri )
      @pid_file = File.join( @spec_dir, "rack.pid" )
      @ru_file  = File.join( @spec_dir, "remote_repo.ru" )
      cmd = "rackup --port 6789 --pid #{@pid_file} --daemonize #{@ru_file}"
      system cmd
      puts "rackup started with pid #{IO.read( @pid_file )}"
      @acc      = ::Resourceful::HttpAccessor.new
      sleep 2
      @acc.resource( @repo_uri + "yaml" ).get
    end

    after do
      pid = IO.read( @pid_file ).to_i
      Process.kill( 'KILL', pid )
      Process.wait
      FileUtils.rm_rf( @tmp_dir )
    end


    it_should_behave_like 'implements Repository::Api'
  end
end

