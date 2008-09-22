require 'ostruct'
require 'open-uri'

module Stickler
  #
  # A class that fetches gems and all its dependencies from a series of remote
  # sources and installs them into the appropriate locations in the Repository.
  #
  class Installer

    class Error < StandardError ; end

    # The repository this Installer installes into
    attr_reader :repository

    def initialize( repository )
      @repository = repository
    end

    def logger
      @logger ||= ::Logging::Logger[self]
    end

    def installed_specs 
      @installed_specs ||= {}
    end

    #
    # Install the gem given by the spec and all of its dependencies.
    #
    def install( install_info )
      install_list = []

      todo = []
      todo << install_info.dup
      seen = {}

      until todo.empty? do
        spec_meta = todo.pop
        logger.debug "queueing #{spec_meta.spec.full_name} for download"

        install_list << spec_meta

        next if seen[ spec_meta.spec.full_name ] or installed_specs[ spec_meta.spec.full_name ]
        seen[ spec_meta.spec.full_name ] = true

        deps = spec_meta.spec.runtime_dependencies 
        deps |= spec_meta.spec.development_dependencies

        deps.each do |dep|
          results = find_specs_satisfying_dependency( dep )

          results.reverse! if repository.requirement_satisfaction_method == :minimum 

          todo.push matching_from_each_platform( results )
          todo.flatten!
        end

      end

      install_gems_and_specs( install_list )
    end

    #
    # collect the highest version from each distinct platform in the results and
    # return that list
    #
    def matching_from_each_platform( results )
      by_platform = {}
      until results.empty?
        r = results.pop
        if not by_platform.has_key?( r.spec.platform.to_s ) then
          by_platform[ r.spec.platform.to_s ] = r 
          logger.debug "adding #{ r.spec.full_name } for platform #{r.spec.platform.to_s} for dependency evaluation"
        end
      end
      return by_platform.values
    end

    #
    # Get the list of gems that satisfy the given dependency and return in
    # sorted order from lowest to highest version number
    #
    def find_specs_satisfying_dependency( dep )
      results = []
      repository.source_cache.search_with_source( dep ).each do |spec, source_uri|
        result = OpenStruct.new
        result.spec = spec
        result.source_uri = source_uri
        results <<  result
      end
      raise Error, "Unable to find gem satisfying dependendcy #{dep.to_s}" if results.empty?

      results.sort_by { |r| r.spec.version }
    end

    private

    def install_gem( spec, source_uri )
      Stickler.tee "installing #{ spec.full_name }"
      gem_file = "#{spec.full_name}.gem"
      dest_gem_file = File.join( repository.gem_dir, gem_file )

      if not File.exist?( dest_gem_file ) then
        open( File.join( source_uri, 'gems', gem_file ), "rb" ) do |gem|
          File.open( dest_gem, "wb" ) do |f|
            f.write( gem.read )
          end
        end
        logger.debug "  downloaded to #{dest_gem_file}"
      else
        logger.debug "  already exists #{dest_gem_file}"
      end
      return dest_gem_file 
    end

    def install_spec( spec )
      rubycode = spec.to_ruby
      file_name = File.join( repository.specification_dir, "#{spec.full_name}.gemspec" )
      File.open( file_name, "wb" ) do |file|
        file.puts rubycode 
      end
    end

    def install_gems_and_specs( install_list )
      install_list.each do |install_info|
        spec       = install_info.spec
        source_uri = install_info.source_uri 

        install_gem( spec, source_uri )
        install_spec( spec )
      end
    end
  end
end

