
if RUBY_VERSION >= '1.9.2' then
  require 'simplecov'
  SimpleCov.start if ENV['COVERAGE']
end

gem 'minitest'
require 'minitest/autorun'
require 'minitest/pride'
require 'stickler'
require 'index_test_helpers'

module Stickler
  class Test < ::Minitest::Test
    def test_dir
      File.expand_path( File.dirname( __FILE__ ) )
    end

    def gem_root
      File.join( test_dir, 'data' )
    end

    def specifications_dir
       File.join( gem_root, "specifications" )
    end

    def gems_dir
      File.join( gem_root, "gems" )
    end

    def teardown
      ::Stickler::Repository::Local.purge
    end

    def assert_raises_kind_of *exp
      msg = "#{exp.pop}.\n" if String === exp.last

      begin
        yield
      rescue Exception => e
        expected = exp.any? { |ex| e.kind_of? ex }
        assert expected, proc {
          exception_details(e, "#{msg}#{mu_pp(exp)} exception expected, not")
        }
        return e
      end
    end
  end
end
