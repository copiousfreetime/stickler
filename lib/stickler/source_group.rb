module Stickler
  # 
  # A source group contains a set of Source objects, and runs common operations
  # across all of them. 
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

    #
    # The root directory of the repository
    #
    def root_dir
      @root_dir || repository.directory
    end

    #
    # The specification directory in the repository
    #
    def specification_dir
      @specification_dir ||= repository.specification_dir
    end

    # 
    # The specification behavior
    #
    def requirement_satisfaction_behavior
      @requirement_satisfaction_behavior ||= repository.requirement_satisfaction_behavior
    end

    #
    # The directory housing the actual .gem files
    #
    def gems_dir
      @gems_dir ||= repository.gems_dir
    end

    #
    # logger for this class
    #
    def logger
      @logger ||= ::Logging::Logger[self]
    end

    # 
    # Add a source to the source group
    #
    def add_source( source_uri )
      s = Source.new( source_uri, self )
      @sources[s.uri] = s
    end

    #
    # accessor for the available Source objects in this group
    #
    def sources
      @sources.values
    end

    #
    # Access all the gems that are in this gemspec This is a Hash of all gems in
    # the source group. The keys are spec.full_name and the values are
    # Gem::Specification instances
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
    # Force a reload of the gem from the existing specs
    #
    def reload_gems!
      @gems = nil
      gems
    end

    #
    # Return a list of Gem::Specification instances corresponding to the
    # existing gems for a particular source
    #
    def existing_specs_for_source_uri( uri )
      unless @existing_specs_for_source_uri
        logger.debug "Loading existing_specs_for_source_uri"
        @existing_specs_for_source_uri = Hash.new{ |h,k| h[k] = Array.new }
        gems.values.each do |spec|
          @existing_specs_for_source_uri[ source_uri_for_spec( spec ) ] << spec
        end
      end
      @existing_specs_for_source_uri[ Source.normalize_uri( uri ) ]
    end

    #
    # Search through all sources for all gems that satisfy the given
    # Gem::Dependency
    #
    def search( dependency )
      results = []
      @sources.each_pair do |uri, src|
        results.concat( src.search( dependency ) )
      end
      return results
    end

    #
    # Search through all the existing specs for gemes that match the given
    # Gem::Dependency
    #
    def search_existing( dependency )
      results = gems.values.find_all do |spec|
        dependency =~ Gem::Dependency.new( spec.name, spec.version )
      end
    end

    #
    # Add the gem that satisfies the dependency based upon the current
    # satisfication method
    #
    def add_from_dependency( dep )
      Console.info "Resolving gem dependencies for #{dep.to_s} ..."
      specs_satisfying_dependency( dep ).each do |s|
        add( s )
      end
    end

    #
    # Add the gem given by the spec and all of its dependencies.
    #
    def add( spec )
      top_spec = spec
      unless spec.instance_of?( ::Gem::Specification )
        source_uri = source_uri_for_spec( spec )
        top_spec   = @spec_fetcher.fetch_spec( spec.to_a, source_uri )
      end

      add_list = []

      todo = []
      todo.push top_spec
      seen = {}

      until todo.empty? do
        spec = todo.pop
        next if seen[ spec.full_name ] or gems[ spec.full_name ] 

        logger.info "Queueing #{spec.full_name} for download"
        add_list << spec

        seen[ spec.full_name ] = true

        deps = spec.runtime_dependencies 
        deps |= spec.development_dependencies

        deps.each do |dep|
          specs_satisfying_dependency( dep ).each do |s|
            todo.push s
          end
        end
      end

      add_gems_and_specs( add_list )
      reload_gems!
    end


    #
    # unisntall the gem given by the spec and all gems that depend on it.
    #
    def remove( spec_or_list )
      Console.info "Resolving remove dependencies..."

      todo = [ spec_or_list ].flatten
      remove_list = []

      until todo.empty? do
        spec = todo.pop
        next if remove_list.include?( spec )

        logger.info "queueing #{spec.full_name} for removal"
        remove_list << spec

        sibling_gems_of( spec ).each do |sspec|
          Console.debug "pushing #{sspec.full_name} onto todo list"
          todo.push sspec
        end

        specs_depending_on( spec ).each do |dspec|
          Console.debug "pushing #{dspec.full_name} onto todo list"
          todo.push dspec 
        end
      end

      remove_gems_and_specs( remove_list )
      reload_gems!
    end

    #
    # Return the list of existing Specifications that have the same name as
    # then given spec
    #
    def sibling_gems_of( spec )
      sibs = []
      gems.values.each do |gspec|
        if spec.name == gspec.name and spec.full_name != gspec.full_name then
          sibs << gspec
        end
      end
      return sibs
    end

    #
    # Get the list of existing Specifications that have the input spec as
    # either a runtime or development dependency
    #
    def specs_depending_on( spec )
      deps = []
      gems.values.each do |gspec|
        gspec.dependencies.each do |dep|
          if spec.satisfies_requirement?( dep ) then
            deps << gspec
            break
          end
        end
      end
      return deps
    end

    #
    # Get the list of Specifications that satisfy the dependency 
    # based upon the current requirement satisfaction method
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

    #
    # return the URI of the Source object that houses the upstream gem 
    #
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


    #
    # remove the source from the source group
    #
    def remove_source( source_uri )
      ulist = existing_specs_for_source_uri( source_uri )
      remove( ulist )
      @sources.delete( source_uri )
      logger.info "removed #{source_uri}"
    end

    #
    # Remove a list of gems from specifications
    #
    def remove_gems_and_specs( remove_list )
      while spec = remove_list.pop do
        Console.info "Removeing #{ spec.full_name }"
        delete_gem_files( spec )
      end
    end

    #
    # Remove all files from the repository related to this specification
    #
    def delete_gem_files( spec )
      FileUtils.rm_f( File.join( gems_dir, "#{spec.full_name}.gem" ) )
      FileUtils.rm_f( File.join( specification_dir, "#{spec.full_name}.gemspec" ))
    end

    #
    # Add the gem represented by the spec
    #
    def add_gem( spec )

      local_fetch_path = @fetcher.download( spec, source_uri_for_spec( spec ).to_s, root_dir )
      dest_gem_path    = File.join( gems_dir, File.basename( local_fetch_path ) )
      logger.info  "copying #{local_fetch_path} to #{dest_gem_path}"
      FileUtils.cp local_fetch_path, dest_gem_path

      return dest_gem_path
    end


    # 
    # Add the specification
    #
    def add_spec( spec )
      rubycode = spec.to_ruby
      file_name = File.join( specification_dir, "#{spec.full_name}.gemspec" )
      logger.info  "writing #{file_name}"
      File.open( file_name, "wb" ) do |file|
        file.puts rubycode 
      end
    end


    # 
    # Add all the gems and specifications in the add list
    #
    def add_gems_and_specs( add_list )
      while spec = add_list.pop do
        Console.info "Adding #{ spec.full_name }"
        add_gem( spec )
        add_spec( spec )
      end
    end
  end
end
