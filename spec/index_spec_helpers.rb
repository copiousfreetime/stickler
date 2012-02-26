require 'rack/test'
require 'rubygems/user_interaction'
require 'rubygems/indexer'

module IndexSpecHelpers
  include Rack::Test::Methods

  def define_directories
    # pristine spec data location
    @idx_spec_dir        = File.expand_path( File.dirname( __FILE__ ) )
    @idx_spec_datadir    = File.join( @idx_spec_dir, "data" )

    # scratch location
    @scratch_dir     = File.join( @idx_spec_dir, "scratch" )
    @scratch_datadir = File.join( @scratch_dir, 'data' )
    @scratch_specdir = File.join( @scratch_datadir, "specifications" )
    @scratch_gemsdir = File.join( @scratch_datadir, "gems" )
  end

  # put in the before clause for setup
  def mirror_spec_gemdir
    define_directories
    FileUtils.mkdir_p( @scratch_dir )
    FileUtils.cp_r( @idx_spec_datadir, @scratch_dir )
  end

  # Do a legacy index of the scratch location
  def make_legacy_index
    indexer = Gem::Indexer.new( @scratch_datadir, :build_legacy => true, :build_modern => false )
    with_quieter_rubygems { indexer.generate_index }
  end

  # Do a modern index of the scratch location
  def make_modern_index
    indexer = Gem::Indexer.new( @scratch_datadir, :build_legacy => false, :build_modern => true )
    with_quieter_rubygems { indexer.generate_index }
  end

  # put in the after clause for cleanup
  def destroy_scratch_dir
    FileUtils.rm_rf( @scratch_dir )
  end

  def with_quieter_rubygems( &block )
    previous = Gem.configuration.verbose
    Gem.configuration.verbose = nil
    yield
    Gem.configuration.verbose = previous
  end

  def validate_contents( got, expected, content_type)
    case content_type
    when 'application/x-gzip'
      response_un = Gem.gunzip( got      )
      expected_un = Gem.gunzip( expected )
    when 'application/x-deflate'
      response_un = Gem.inflate( got      )
      expected_un = Gem.inflate( expected )
    when 'application/octet-stream'
      response_un = got
      expected_un = expected
    else
      fail "Unkonwn content type #{content_type} with data #{got}"
    end

    got  = Marshal.load( response_un )
    got.sort! if got.kind_of?( Array )

    need = Marshal.load( expected_un )
    need.sort! if need.kind_of?( Array )
    got.should == need
  end
end
