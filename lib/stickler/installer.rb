require 'ostruct'
require 'open-uri'

module Stickler
  #
  # A class that fetches gems and all its dependencies from a series of remote
  # sources and installs them into the appropriate locations in the Repository.
  #
  class Installer

    class Error < StandardError ; end

    # The SourceGroup this installers belongs to
    attr_reader :source_group

    def initialize( source_group )
      @source_group = source_group
    end

    def logger
      @logger ||= ::Logging::Logger[self]
    end

    def installed_specs 
      unless @installed_specs
        is = {}
        Dir.glob( File.join( source_group.specification_dir, "*.spec" ) ).each do |spec_file|
          begin
            spec = eval( IO.read( spec_file ) )
            is[spec.full_name] = spec
          rescue => e
            logger.error "Failure loading specfile #{File.basenem(spec_file)} : #{e}"
          end
        end
        @installed_specs = is
      end
      return @installed_specs
    end

    #
    # Install the gem given by the spec and all of its dependencies.
    #
    def install( spec_info )
      spec_name, version, original_platform  = spec_info
      install_list = []

      todo = []
      todo << top_spec
      seen = {}

      until todo.empty? do
        spec = todo.pop
        next if seen[ spec.full_name ] or installed_specs[ spec.full_name ]

        seen[ spec.full_name ] = true

        logger.debug "queueing #{spec.full_name} for download"
        install_list << spec

        deps = spec.runtime_dependencies 
        deps |= spec.development_dependencies

        deps.each do |dep|
          results = find_specs_satisfying_dependency( dep )

          results.reverse! if source_group.requirement_satisfaction_method == :minimum 

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
        spec = results.pop
        if not by_platform.has_key?( spec.platform.to_s ) then
          by_platform[ spec.platform.to_s ] = spec
          logger.debug "adding #{ spec.full_name } for platform #{spec.platform.to_s} for dependency evaluation"
        end
      end
      return by_platform.values
    end

    #
    # Get the list of gems that satisfy the given dependency and return in
    # sorted order from lowest to highest version number
    #
    def find_specs_satisfying_dependency( dep )
      results = source_group.search( dep )
      raise Error, "Unable to find gem satisfying dependendcy #{dep.to_s}" if results.empty?

      results.sort_by { |s| s.version }
    end

    private

    def install_gem( spec )
      Console.info "installing #{ spec.full_name }"
      gem_file = "#{spec.full_name}.gem"
      dest_gem_file = File.join( source_group.gems_dir, gem_file )

      if not File.exist?( dest_gem_file ) then
        logger.debug "getting source_uri for #{spec.full_name}"
        uri = source_group.full_uri_for_spec( spec )
        logger.debug "  downloading #{uri}"
        begin
          open( uri, "rb" ) do |upstream_gem|
            File.open( dest_gem_file, "wb" ) do |f|
              f.write( upstream_gem.read )
            end
          end
        rescue => e
          Console.error "Error downloading #{uri} : #{e}"
        end
        logger.debug "  downloaded to #{dest_gem_file}"
      else
        logger.debug "  already exists #{dest_gem_file}"
      end
      return dest_gem_file 
    end

    def install_spec( name, version, platform )
      rubycode = spec.to_ruby
      file_name = File.join( source_group.specification_dir, "#{spec.full_name}.gemspec" )
      File.open( file_name, "wb" ) do |file|
        file.puts rubycode 
      end
    end

    def install_gems_and_specs( install_list )
      install_list.each do |spec|
        install_gem( spec )
        install_spec( spec )
      end
    end
  end
end

