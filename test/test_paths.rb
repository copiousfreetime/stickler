require 'test_stickler'
require 'pathname'

module Stickler
  class TestPaths < Test
    def setup
      @root_path = Pathname.new( __FILE__ ).dirname.parent.expand_path
    end

    def add_trailing_separator( x )
      x.to_s + ::File::SEPARATOR
    end

    def test_accessing_the_root_dir_of_the_project
      assert_equal( add_trailing_separator( @root_path ), Stickler::Paths.root_dir )
    end

    def test_accessing_the_lib_dir_of_the_project
      assert_equal( add_trailing_separator( @root_path.join('lib')), Stickler::Paths.lib_path )
    end
  end
end
