require File.expand_path( File.join( File.dirname(__FILE__), "spec_helper.rb" ) )
require File.expand_path( File.join( File.dirname(__FILE__), "repository_api_behavior.rb" ) )

require 'stickler/repository/remote'

describe Stickler::Repository::Remote do
  before do
    @repo_uri = "http://localhost:6789/"
    @repo     = ::Stickler::Repository::Remote.new( @repo_uri )
  end

  it_should_behave_like 'includes Repository::Api'

  describe "Using a live server" do
    before do
      @tmp_dir  = File.join( @spec_dir, "tmp" )
      FileUtils.mkdir_p( @tmp_dir )

      @pid_file = File.join( @tmp_dir , "rack.pid" )
      @ru_file  = File.join( @spec_dir, "remote_repo.ru" )
      cmd = "rackup --port 6789 --pid #{@pid_file} --daemonize #{@ru_file}"
      system cmd

      tries = 0
      @acc      = ::Resourceful::HttpAccessor.new
      loop do
        begin
          @acc.resource( @repo_uri + "specs.#{Gem.marshal_version}.gz" ).get
          #puts "rackup started with pid #{IO.read( @pid_file )}"
          break
        rescue => e
          tries += 1
          sleep tries * 0.1
        end
      end
    end

    after do
      pid = IO.read( @pid_file ).to_i
      Process.kill( 'KILL', pid )
      FileUtils.rm_rf( @tmp_dir )
    end

    it_should_behave_like 'implements Repository::Api'
  end
end

