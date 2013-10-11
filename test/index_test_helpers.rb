require 'rack/test'
require 'rubygems/user_interaction'
require 'rubygems/indexer'

module Stickler
  module IndexTestHelpers
    include Rack::Test::Methods

    def define_directories
      # pristine spec data location
      @idx_test_dir        = File.expand_path( File.dirname( __FILE__ ) )
      @idx_test_datadir    = File.join( @idx_test_dir, "data" )

      # scratch location
      @scratch_dir     = File.join( @idx_test_dir, "scratch" )
      @scratch_datadir = File.join( @scratch_dir, 'data' )
      @scratch_specdir = File.join( @scratch_datadir, "specifications" )
      @scratch_gemsdir = File.join( @scratch_datadir, "gems" )
    end

    # put in the before clause for setup
    def mirror_spec_gemdir
      define_directories
      FileUtils.mkdir_p( @scratch_dir )
      FileUtils.cp_r( @idx_test_datadir, @scratch_dir )
    end

    # Do a legacy index of the scratch location
    def make_legacy_index
      indexer = Gem::Indexer.new( @scratch_datadir, :build_legacy => true, :build_modern => false )
      quiet_indexing( indexer )
    end

    # Do a modern index of the scratch location
    def make_modern_index
      indexer = Gem::Indexer.new( @scratch_datadir, :build_legacy => false, :build_modern => true )
      quiet_indexing( indexer )
    end

    # put in the after clause for cleanup
    def destroy_scratch_dir
      FileUtils.rm_rf( @scratch_dir )
    end


    def quiet_indexing( indexer )
      indexer.use_ui( Gem::SilentUI.new ) do
        indexer.generate_index
      end
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
        assert false, "Unkonwn content type #{content_type} with data #{got}"
      end

      got  = Marshal.load( response_un )
      got.sort! if got.kind_of?( Array )

      need = Marshal.load( expected_un )
      need.sort! if need.kind_of?( Array )
      return need, got
    end
  end
end
