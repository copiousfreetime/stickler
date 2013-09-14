class SticklerTestServer
  def initialize( test_dir, ru_file )
    @test_dir = test_dir
    @repo_uri = "http://localhost:6789/"
    @tmp_dir  = File.join( @test_dir , "tmp" )
    FileUtils.mkdir_p( @tmp_dir )

    @pid_file = File.join( @tmp_dir , "rack.pid" )
    @ru_file  = File.expand_path( File.join( @test_dir , "..", "examples", ru_file ) )
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
      rescue
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

