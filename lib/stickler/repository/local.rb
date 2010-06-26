require 'stickler/spec_lite'
require 'stickler/repository'
require 'stickler/repository/api'
require 'addressable/uri'
require 'tempfile'

module Stickler::Repository
  #
  # A local repository of gems.  It implements the Repository::Api
  # and stores all the gems and specifications local to a root directory.
  #
  # It currently has two subdirectories:
  #
  # gems/           -> holding the .gem files 
  # specifications/ -> holding the .gemspec files
  #
  #
  class Local
    class Error < ::Stickler::Repository::Error; end

    # the root directory of the repository
    attr_reader :root_dir

    # the directory containing the .gem files
    attr_reader :gems_dir
   
    # the directory containing the .gemspec files
    attr_reader :specifications_dir

    # a temporary directory for odds and ends
    attr_reader :temp_dir

    def initialize( root_dir )
      @root_dir = File.expand_path( root_dir ) + File::SEPARATOR
      @gems_dir = File.join( @root_dir, 'gems/' )
      @specifications_dir = File.join( @root_dir, 'specifications/' )
      @temp_dir = File.join( @root_dir, "tmp/" )
      @index = Gem::SourceIndex.new
      setup_dirs
    end

    #
    # See Api#uri
    #
    def uri
      @uri ||= Addressable::URI.convert_path( root_dir )
    end

    # 
    # See Api#gems_uri
    #
    def gems_uri
      @gems_uri ||= Addressable::URI.convert_path( gems_dir )
    end

    #
    # See Api#uri_from_gem
    #
    def uri_for_gem( spec )
      return nil unless gem_file_exist?( spec )
      return self.gems_uri.join( spec.file_name )
    end

    #
    # The Repository::Index of this repo.
    #
    def index
      @index.load_gems_in( specifications_dir )
      return @index
    end

    #
    # See Api#search_for
    #
    def search_for( spec )
      platform = Gem::Platform.new( spec.platform )
      dep      = Gem::Dependency.new( spec.name, spec.version )
      specs    = index.search( dep )
      specs    = specs.find_all { |spec| spec.platform == platform }
      return specs
    end

    #
    # See Api#delete
    #
    def delete( spec )
      uninstall( spec )
    end

    # 
    # See Api#yank
    #
    def yank( spec )
      uninstall_specification( spec ) if specification_file_exist?( spec )
      return uri_for_gem( spec )
    end


    #
    # :call-seq:
    #   repo.add( io ) -> Stickler::SpecLite
    #
    # A lower level version of #push.  The item passed in is an IO like object
    # that contains the binary stream that is a .gem file.  IO must respond to
    # #read and #rewind.
    #
    def add( io )
      # spooling to a temp file because Gem::Format.from_io() closes the io
      # stream it is sent.  Why it does this, I do not know.
      tempfile = Tempfile.new(  "uploaded-gem.", temp_dir )
      tempfile.write( io.read )
      format    = Gem::Format.from_file_by_path( tempfile.path )
      spec      = Stickler::SpecLite.new( format.spec.name, format.spec.version, format.spec.platform )
      specs     = search_for( spec )
      raise Error, "gem #{spec.full_name} already exists" unless specs.empty?
      tempfile.rewind
      return install( spec, tempfile )
    ensure
      tempfile.close!
    end

    #
    # See Api#push
    #
    def push( path )
      spec = specification_from_gem_file( path )
      result = nil
      File.open( path ) do |io|
        result = add( io )
      end
      return result
    end

    #
    # See Api#get
    #
    def get( spec )
      return IO.read( full_path_to_gem( spec ) ) if gem_file_exist?( spec )
      return nil
    end

    #
    # See Api#open
    #
    def open( spec, &block )
      return nil unless gem_file_exist?( spec )
      path = full_path_to_gem( spec )
      f = File.open( path, "rb" )
      if block_given? then
        begin
          yield f
        ensure
          f.close
        end
      else
        return f
      end
      return nil
    end

    private

    def setup_dirs
      [ root_dir, specifications_dir, gems_dir, temp_dir ].each do |dir|
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
      return speclite_from_specification( gemspec )
    end

    def uninstall( spec )
      uninstall_gem( spec )
      uninstall_specification( spec )
    end

    def uninstall_gem( spec )
      remove_file( full_path_to_gem( spec ) )
    end

    def uninstall_specification( spec )
      remove_file( full_path_to_specification( spec ) )
    end

    def remove_file( path )
      return false unless File.exist?( path )
      return true  if File.unlink( path ) > 0
    end

    def gem_file_exist?( spec )
      File.exist?( full_path_to_gem( spec ) )
    end

    def specification_file_exist?( spec )
      File.exist?( full_path_to_specification( spec ) )
    end

    def specification_from_gem_file( path )
      format = Gem::Format.from_file_by_path( path )
      return format.spec
    end

    def speclite_from_specification( spec )
      Stickler::SpecLite.new( spec.name, spec.version.to_s, spec.platform )
    end
  end
end
