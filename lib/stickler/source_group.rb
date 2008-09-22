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
    end

    def cache_dir
      @cache_dir ||= repository.upstream_source_cache_dir
    end

    def logger
      @logger ||= ::Logging::Logger[self]
    end

    def add_source( source_uri )
      @sources[source_uri] = Source.load( source_uri, self, :eager => true )  
    end

    def sources
      @sources.values
    end

    def remove_source( source_uri )
      if src = @sources.delete( source_uri ) then
        logger.info "destroyed #{source_uri}"
        src.destroy!
      end
    end
  end
end
