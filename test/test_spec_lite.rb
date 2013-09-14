require 'test_stickler'

module Stickler
  class TestSpecLite < Test
    def setup
      @specs = {
        :ruby => Stickler::SpecLite.new( 'foo', '0.4.2' ),
        :win  => Stickler::SpecLite.new( 'bar', '1.0.1', "x86-mswin32" ),
        :java => Stickler::SpecLite.new( 'jfoo', '0.4.2', 'jruby' )
      }
    end

    def test_defaults_to_ruby_platform
      assert_equal Gem::Platform::RUBY, @specs[:ruby].platform
    end

    def test_platform_methods
      { [:ruby, 'file_name']      => "foo-0.4.2.gem",
          [:ruby, 'spec_file_name'] => "foo-0.4.2.gemspec" ,
          [:win , 'file_name']      => "bar-1.0.1-x86-mswin32.gem",
          [:win , 'spec_file_name'] => "bar-1.0.1-x86-mswin32.gemspec",
          [:java, 'file_name']      => 'jfoo-0.4.2-jruby.gem',
          [:java, 'spec_file_name'] => 'jfoo-0.4.2-jruby.gemspec',
       }.each do |params, result|
        platform, method = *params
        assert_equal result, @specs[platform].send(method), "on a #{platform} gem #{method} is #{result}"
       end
    end

    def test_array_format
      assert_equal [ 'bar', '1.0.1', 'x86-mswin32' ], @specs[:win].to_a
    end

    def test_returns_false_when_not_similar
      refute_match @specs[:ruby], Object.new
    end

    def test_returns_true_when_is_similar
      o = OpenStruct.new( :name => @specs[:ruby].name, 
                          :version => @specs[:ruby].version, 
                          :platform_string => @specs[:ruby].platform_string )

      assert_match @specs[:ruby], o
    end

    def test_compare_to_another_spec
      refute_match @specs[:ruby], @specs[:win]
    end

    def test_compare_to_same_name_and_version_different_platform
      list = []
      list << r = Stickler::SpecLite.new( 'alib', '4.2' )
      list << u = Stickler::SpecLite.new( 'alib', '4.2', 'x86-mswin32' ) 
      assert_equal [ r, u ], list.sort
    end

    def test_different_platforms_may_be_compared
      list = []
      list << h2 = Stickler::SpecLite.new( 'htimes', '1.1.1', 'x86-mingw32' )
      list << h1 = Stickler::SpecLite.new( 'htimes', '1.1.1', 'java' )
      assert_equal [h1, h2], list.sort
    end

    def test_sorting
      list = @specs.values
      alib = Stickler::SpecLite.new( 'alib', '4.2' )
      list << alib
      result = [ alib, @specs[:win], @specs[:ruby], @specs[:java] ]
      assert_equal result, list.sort
    end

    def test_is_prerelease
      spec = Stickler::SpecLite.new( 'prerelease', '1.2.3a' )
      assert_predicate spec, :prerelease?
    end

    def test_not_prerelease
      spec = Stickler::SpecLite.new( 'prerelease', '1.2.3' )
      refute_predicate spec, :prerelease?
    end

    def test_version_sortable
      l = []
      l << a = Stickler::SpecLite.new( "foo", "1.0.3" )
      l << b = Stickler::SpecLite.new( "foo", "1.0.22" )
      l << c = Stickler::SpecLite.new( "foo", "1.0.17" )
      assert_equal [a, c, b], l.sort
    end
  end
end
