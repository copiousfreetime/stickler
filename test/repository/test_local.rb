require 'test_stickler'
require 'repository/test_api'

module Stickler
  class LocalRepositoryTest < Test
    include RepositoryApiBehaviorTests
    attr_reader :repo

    def repos_dir
      File.join( test_dir, "repos" )
    end

    def repo_dir
      File.join( repos_dir, "1" )
    end

    def repo
      @repo ||= ::Stickler::Repository::Local.new( repo_dir )
    end

    def teardown
      super
      FileUtils.rm_rf( repos_dir )
    end

    def test_creates_gems_directory
      repo.gems_dir
      new_dir = File.join( repo_dir , 'gems') + File::SEPARATOR
      assert File.directory?( new_dir ), "#{new_dir} must be a directory"
      assert_equal new_dir, repo.gems_dir
    end

    def test_creates_specifications_directory
      repo.specifications_dir
      new_dir = File.join( repo_dir , 'specifications' ) + File::SEPARATOR
      assert File.directory?( new_dir ), "#{new_dir} must be a directory"
      assert_equal new_dir, repo.specifications_dir
    end

    def test_lists_all_specs_in_the_repo
      Dir.glob( File.join( gems_dir, "*.gem" ) ).each do |gem|
        repo.push( gem )
      end
      assert_equal 5, repo.specs.size
    end

    def test_two_instances_with_the_same_repo_dir_are_the_same_object
      repo2 = ::Stickler::Repository::Local.new( File.join( repos_dir, '1') )
      assert_equal repo.object_id, repo2.object_id
      assert_equal 1, ::Stickler::Repository::Local.repos.size
    end

    def test_tracks_all_repository_instances
      ::Stickler::Repository::Local.new( File.join( repos_dir, "2" ) )
      ::Stickler::Repository::Local.new( File.join( repos_dir, "3" ) )
      assert_equal 2, ::Stickler::Repository::Local.repos.size
    end
  end
end

