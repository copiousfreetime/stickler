require 'stickler/spec_lite'
require 'stickler/repository'

module Stickler::Repository
  #
  # A repository index is a container holding all the SpecLite elements
  # in the repository.  All the gem specs that this index holds are derived
  # from actual files on the file system.
  #
  # It is modelled somewhat like a Gem::SourceIndex.
  #
  class Index
    class Error < ::Stickler::Repository::Error; end 

    # The list of specs in the index
    attr_reader :specs

    # The directory the specs live
    attr_reader :spec_dir

    def initialize( spec_dir )
      @specs = []
      @spec_dir = spec_dir
      load_specs
    end

    def specs
      load_specs if reload_necessary?
      return @specs
    end

    def latest_specs
      latest = {}
      specs.each do |s|
        if old_spec = latest[s.name] then
          if old_spec.version < s.version then
            latest[s.name] = s
          end
        else
          latest[s.name] = s
        end
      end
      latest.values
    end

    def load_specs
      load_specs_in_dir( self.spec_dir )
    end

    def reload_necessary?
      return true unless @last_modified_time
      current_modified_time = File.stat( self.spec_dir ).mtime
      return (current_modified_time > @last_modified_time )
    end

    def last_modified_time
      File.stat( self.spec_dir ).mtime
    end

    def spec_dir=( d )
      raise Error, "#{d} is not a directory" unless File.directory?( d )
      @spec_dir = d
      @last_modified_time = File.stat( d ).mtime
    end

    def load_specs_in_dir( spec_dir )
      return nil unless File.directory?( spec_dir )
      @specs.clear
      self.spec_dir = spec_dir

      Dir.foreach( spec_dir ) do |entry|
        next unless entry =~ /\.gemspec\Z/
        add_spec_from_file( File.join( spec_dir, entry ) )
      end
    end

    def add_spec_from_file( path )
      return nil unless File.exist?( path )
      code = File.read( path )
      full_spec = eval( code, binding, path )
      raise Error, "File #{path} is not Gem::Specification in ruby format" unless full_spec.is_a?( Gem::Specification )

      full_spec.untaint
      spec = Stickler::SpecLite.new( full_spec.name, full_spec.version, full_spec.platform )
      @specs << spec
    end

    def search( find_spec )
      specs.select do |spec|
        spec =~ find_spec
      end
    end
  end
end
