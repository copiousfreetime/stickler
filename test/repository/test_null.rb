require 'test_stickler'
require 'repository/test_api'

module Stickler
  class NullRepoistoryTest < Test
    include RepositoryApiTests
    def repo
      @repo ||= ::Stickler::Repository::Null.new
    end

    def test_null_root_dir_is_class_name
      assert_equal "Stickler::Repository::Null", repo.root_dir
    end
  end
end
