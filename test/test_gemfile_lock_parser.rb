require 'test_stickler'
require 'stickler/gemfile_lock_parser'

module Stickler
  class TestGemfileLockParser < Test
    def setup
      @lockfile = File.join( test_dir, 'data', 'Gemfile.lock.example' )
      @parser   = ::Stickler::GemfileLockParser.new( @lockfile )
    end

    def test_raises_exception_when_file_does_not_exist
      assert_raises( ::Stickler::Error ) {
        ::Stickler::GemfileLockParser.new( File.join( test_dir, 'data', "Gemfile.dne" ) )
      }
    end

    def test_parse_gem_dependencies
      names = %w[ addressable builder excon hpricot json little-plugger logging
      minitest multi_json mustache rack rack-protection rack-test rake
      rdiscount rdoc ronn sinatra tilt trollop ]
      names.each do |n|
        assert @parser.depends_on?( n ), "fails to depend on #{n}"
      end

      assert_equal names.size, @parser.gem_dependencies.size
    end
  end
end
