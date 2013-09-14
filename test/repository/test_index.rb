require 'test_stickler'

module Stickler
  class TestIndexRepository < Test
    def setup
      @index_me = File.join( test_dir, "tmp" )
      FileUtils.mkdir_p( @index_me )

      @specifications = Dir.glob( File.join( specifications_dir, "*.gemspec" ) )
      @specifications.each do |s|
          FileUtils.cp( s, @index_me )
      end
      @index = ::Stickler::Repository::Index.new( @index_me )
    end

    def teardown
      FileUtils.rm_rf( @index_me )
    end

    def test_all_gemspec_files_in_a_directory_are_indexed
      assert_equal @specifications.size, @index.specs.size
    end

    def test_notice_changes_in_the_index
      assert_equal @specifications.size, @index.specs.size
      FileUtils.rm( File.join( @index_me, "foo-1.0.0.gemspec" ) )
      assert_equal @specifications.size-1, @index.specs.size
    end

    def test_latest_specs
      assert_equal( @specifications.size - 1, @index.latest_specs.size )
      expected = %w[ bar-1.0.0 baz-3.1.4 baz-3.1.4-java foo-1.0.0 ]
      assert_equal expected, @index.latest_specs.collect { |s| s.full_name }.sort
    end

    def test_pre_release_specs
      assert_equal 1, @index.prerelease_specs.size
      assert_equal "foo-2.0.0a",@index.prerelease_specs.first.full_name
    end

    def test_released_specs
      assert_equal 4, @index.released_specs.size
      expected = %w[ bar-1.0.0 baz-3.1.4 baz-3.1.4-java foo-1.0.0 ]
      assert_equal expected, @index.released_specs.collect { |s| s.full_name }.sort
    end
  end
end

