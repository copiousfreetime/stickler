require 'fileutils'
require 'addressable/uri'
require 'resourceful'
require 'stickler/spec_lite'
require 'rubygems/format'

module Stickler

  #
  # The Mirror holds the local mirror of an upstream gem repository
  # It is a directory holding a the upstream Marshal.4.8.Z file
  # and 2 sudirectories, 'specifications' and 'gems' to conform to
  # a gem index directory layout.
  #
  class Mirror

    # the root directory of the mirror
    attr_reader :root_dir
    
    # the upstream uri of the mirror
    attr_reader :upstream_uri

    # the http client
    attr_reader :http

    def self.normalize_mirror_path( mirror_path )
      before = Addressable::URI.parse( mirror_path )
      if not before.scheme then
        after = "http://#{before.to_s}"
      end
      return Addressable::URI.parse( after )
    end

    def initialize( parent_dir, mirror_path )
      @root_dir     = File.join( File.expand_path( parent_dir ), mirror_path )
      @upstream_uri = Mirror.normalize_mirror_path( mirror_path )
      @http         = Resourceful::HttpAccessor.new( :cache_manager => Resourceful::InMemoryCacheManager.new )
      @local_source_index = Gem::SourceIndex.new
      setup_dirs
    end

    def upstream_specs_uri
      @upstream_specs_uri ||= Addressable::URI.join( upstream_uri, "/specs.#{Gem.marshal_version}.gz" )
    end

    def specifications_dir
      @specficiations_dir ||= File.join( root_dir, 'specifications' )
    end

    def gems_dir
      @gems_dir ||= File.join( root_dir, 'gems' )
    end

    def upstream_source_index_resource
      @upsteam_source_index_resource ||= @http.resource( upstream_specs_uri )
    end

    def upstream_source_index
      Marshal.load( download_upstream_specs( upstream_specs_uri ) )
    end

    def local_source_index
      @local_source_index.load_gems_in( specifications_dir )
      return @local_source_index
    end

    def search_local_source_index_for( spec )
      found = []
      platform = Gem::Platform.new( spec.platform )
      dep      = Gem::Dependency.new( spec.name, spec.version )
      specs    = local_source_index.search( dep )
      specs    = specs.find_all { |spec| spec.platform == platform }
      return specs
    end

    def search_upstream_source_index_for( spec )
      found = []
      upstream_source_index.each do |name, version, platform|
        up_spec = SpecLite.new( name, version, platform )
        found << up_spec if spec =~ up_spec 
      end
      return found
    end

    # add the given gem as much as possible.  The options are:
    #
    #   :name, :version, :platform
    #
    # It will the specific gem.  If there are more than one gems that match the
    # criteria passed in, then it will raise an error.  It returns the SpecLite
    # object from the gem file
    #
    def add_gem( opts = {} )
      spec  = SpecLite.new( opts[:name], opts[:version], opts[:platform] )
      specs = search_local_source_index_for( spec )
      return specs.first unless specs.empty?
      
      specs = search_upstream_source_index_for( spec )
      return fetch_and_install( specs.first )
    end

    private

    def setup_dirs
      [ root_dir, specifications_dir, gems_dir ].each do |dir|
        FileUtils.mkdir_p( dir ) unless File.directory?( dir )
      end
    end

    def fetch_and_install( spec )
      dest_file = download_gem( spec )
      full_spec = install_specification_from( dest_file )
      return SpecLite.new( full_spec.name, full_spec.version, full_spec.platform )
    end

    def install_specification_from( file_path )
      format = Gem::Format.from_file_by_path( file_path )
      spec_file = File.join( specifications_dir, format.spec.full_name + ".gemspec" )
      File.open( spec_file, "w+" ) do |f|
        f.write( format.spec.to_ruby )
      end
      return format.spec
    end

    # download the gem and return the file system location where it was
    # installed
    def download_gem( spec )
      dest_file = File.join( gems_dir, spec.file_name )
      File.open( dest_file, "w+" ) do |f|
        r = http.resource( upstream_uri.join( "gems/#{spec.file_name}" ) )
        resp = r.get
        f.write( resp.body )
      end
      return dest_file
    end

    def download_upstream_specs( uri )
      resp = upstream_source_index_resource.get
      Gem.gunzip( resp.body )
    end
  end
end
