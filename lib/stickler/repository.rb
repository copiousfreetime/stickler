require 'stickler/spec_lite'
require 'stickler/error'
require 'rubygems/source_index'
require 'rubygems/format'
require 'rubygems/platform'
require 'rubygems/dependency'

module Stickler
  #
  # A repository of gems.  It is a blend of a Gem::Indexer
  # repository directory structure and a GEM_PATH directory.
  # structure.
  #
  # It currently has two subdirectories:
  #
  # gems/           -> holding the .gem files 
  # specifications/ -> holding the .gemspec files
  #
  #
  class Repository
    class Error < ::Stickler::Error; end
    #
    # the root directory of the repository
    #
    attr_reader :root_dir

    def initialize( root_dir )
      @root_dir = root_dir
      @source_index = Gem::SourceIndex.new
      setup_dirs
    end

    # 
    # sub-directory holding .gem files
    #
    def gems_dir
      @gems_dir ||= File.join( root_dir, 'gems' )
    end

    #
    # sub-directory holding .spec files
    #
    def specifications_dir
      @specficiations_dir ||= File.join( root_dir, 'specifications' )
    end

    def source_index
      @source_index.load_gems_in( specifications_dir )
      return @source_index
    end

    #
    # given something that responds to :name, :version, :platform, 
    # then search for all specs that match 
    #
    def search_for( spec )
      platform = Gem::Platform.new( spec.platform )
      dep      = Gem::Dependency.new( spec.name, spec.version )
      specs    = source_index.search( dep )
      specs    = specs.find_all { |spec| spec.platform == platform }
      return specs
    end

    #
    # Options must contain :name, :version, :body and optionally :platform.
    #
    # :body follows the same rules as the rack input stream
    #
    # If the gem that is to be written to already exists, then an error will be
    # raised.
    #
    # It returns the SpecLite object from the gem file
    #
    def add_gem( opts = {} )
      spec  = SpecLite.new( opts[:name], opts[:version], opts[:platform] )
      specs = search_for( spec )
      raise Error, "gem #{spec.full_name} already exists" unless specs.empty?
      return install( spec, opts[:body] )
    end

    #
    # Add a gem from a filesystem path
    #
    def add_gem_from_file( path )
      spec = specification_from_gem_file( path )
      opts = { :name => spec.name, :version => spec.version.to_s, :platform => spec.platform }
      result = nil
      File.open( path ) do |io|
        result = add_gem( opts.merge( :body => io ) )
      end
      return result
    end


    private

    def setup_dirs
      [ root_dir, specifications_dir, gems_dir ].each do |dir|
        FileUtils.mkdir_p( dir ) unless File.directory?( dir )
      end
    end

    def full_path_to_gem( spec )
      File.join( gems_dir, spec.file_name )
    end

    def full_path_to_specification( spec )
      File.join( specifications_dir, spec.spec_file_name )
    end


    def install( spec, io )
      install_gem( spec, io )
      install_specification( spec )
    end

    def install_gem( spec, io )
      File.open( full_path_to_gem( spec ) , "w+" ) do |of|
        io.each do |str|
          of.write( str )
        end
      end
    end

    def install_specification( spec )
      gemspec = specification_from_gem_file( full_path_to_gem( spec ) )
      File.open( full_path_to_specification( spec ) , "w+" ) do |f|
        f.write( gemspec.to_ruby )
      end
    end

    def specification_from_gem_file( path )
      format = Gem::Format.from_file_by_path( path )
      return format.spec
    end
  end
end
