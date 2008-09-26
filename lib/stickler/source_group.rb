module Stickler
  # 
  # A source group contains a set of Source objects, and runs common operations
  # across all of them.  Searching for gems is the primary one
  #
  class SourceGroup

    # the repository this group belongs to
    attr_reader :repository

    def initialize( repository )
      @repository = repository
      @sources    = {}

      @fetcher      = ::Gem::RemoteFetcher.new( nil )
      @spec_fetcher = ::Gem::SpecFetcher.fetcher
    end

    def root_dir
      @root_dir || repository.directory
    end

    def specification_dir
      @specification_dir ||= repository.specification_dir
    end

    def requirement_satisfaction_behavior
      @requirement_satisfaction_behavior ||= repository.requirement_satisfaction_behavior
    end

    def gems_dir
      @gems_dir ||= repository.gems_dir
    end

    def logger
      @logger ||= ::Logging::Logger[self]
    end

    def add_source( source_uri )
      s = Source.new( source_uri, self )
      @sources[s.uri] = s
    end

    def sources
      @sources.values
    end

    #
    # Access all the gems that are in this gemspec
    # This is a Hash of all gems in the source group keys are spec.full_name and
    # the values are Gem::Specification instances
    #
    def gems
      unless @gems
        @gems = {}
        Dir.glob( File.join( specification_dir, "*.gemspec" ) ).each do |spec_file|
          begin
            logger.info "Loading spec file #{spec_file}"
            spec = eval( IO.read( spec_file ) )
            @gems[ spec.full_name ] = spec
          rescue => e
            logger.error "Failure loading specfile #{File.basename( spec_file )} : #{e}"
          end
        end
      end
      return @gems
    end

    #
    # Return a list of Gem::Specification instances corresponding to the
    # installed gems for a particular source
    #
    def installed_specs_for_source_uri( uri )
      unless @installed_specs_for_source_uri
        logger.debug "Loading installed_specs_for_source_uri"
        @installed_specs_for_source_uri = Hash.new{ |h,k| h[k] = Array.new }
        gems.values.each do |spec|
          @installed_specs_for_source_uri[ source_uri_for_spec( spec ) ] << spec
        end
      end
      @installed_specs_for_source_uri[ Source.normalize_uri( uri ) ]
    end


    def search( dependency )
      results = []
      @sources.each_pair do |uri, src|
        results.concat( src.search( dependency ) )
      end
      return results
    end

    #
    # Install the gem given by the spec and all of its dependencies.
    #
    def install( spec )
      Console.info "Resolving dependencies..."
      source_uri = source_uri_for_spec( spec )
      top_spec   = @spec_fetcher.fetch_spec( spec.to_a, source_uri )

      install_list = []

      todo = []
      todo.push top_spec
      seen = {}

      until todo.empty? do
        spec = todo.pop
        next if seen[ spec.full_name ] or gems[ spec.full_name ] 

        Console.info "Queueing #{spec.full_name} for download"
        install_list << spec

        seen[ spec.full_name ] = true

        deps = spec.runtime_dependencies 
        deps |= spec.development_dependencies

        deps.each do |dep|
          specs_satisfying_dependency( dep ).each do |s|
            todo.push s
          end
        end
      end

      install_gems_and_specs( install_list )
    end

    #
    # Get list of specs that satisfy the dependency based upon the current
    # requirement satisfaction method
    #
    def specs_satisfying_dependency( dep )
      unsorted = search( dep )
      sorted   = unsorted.sort_by { |s| s.version }

      sorted.reverse! if requirement_satisfaction_behavior == :minimum 

      satisfies = [] 
      matching_from_each_platform( sorted ).each do |spec|
        su = source_uri_for_spec( spec )
        satisfies << @spec_fetcher.fetch_spec( spec.to_a, su )
      end

      return satisfies
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
        end
      end
      return by_platform.values
    end

    def source_uri_for_spec( key_spec )
      unless @source_uri_for_spec
        logger.debug "Loading source_uri_to_spec"
        @source_uri_for_spec = {}
        @sources.each_pair do |uri, src|
          src.source_specs.each do | s |
            @source_uri_for_spec[ s.name_version ] = uri
          end
        end
      end
      @source_uri_for_spec[ key_spec.name_version ]
    end


    def remove_source( source_uri )
      if src = @sources.delete( source_uri ) then
        logger.info "destroyed #{source_uri}"
        src.destroy!
      end
    end

    def install_gem( spec )

      local_fetch_path = @fetcher.download( spec, source_uri_for_spec( spec ).to_s, root_dir )
      dest_gem_path    = File.join( gems_dir, File.basename( local_fetch_path ) )
      logger.info  "copying #{local_fetch_path} to #{dest_gem_path}"
      FileUtils.cp local_fetch_path, dest_gem_path

      return dest_gem_path
    end

    def install_spec( spec )
      rubycode = spec.to_ruby
      file_name = File.join( specification_dir, "#{spec.full_name}.gemspec" )
      logger.info  "writing #{file_name}"
      File.open( file_name, "wb" ) do |file|
        file.puts rubycode 
      end
    end

    def install_gems_and_specs( install_list )
      while spec = install_list.pop do
        Console.info "Installing #{ spec.full_name }"
        install_gem( spec )
        install_spec( spec )
      end
    end
 
  end
end
