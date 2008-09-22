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

    def specification_dir
      @specification_dir ||= repository.specification_dir
    end

    def requirement_satisfaction_method
      @requirement_satisfaction_method ||= repository.requirement_satisfaction_method
    end

    def gems_dir
      @gems_dir ||= repository.gems_dir
    end

    def installer
      @installer || ::Stickler::Installer.new( self )
    end

    def logger
      @logger ||= ::Logging::Logger[self]
    end

    def add_source( source_uri )
      @sources[source_uri] = Source.load( source_uri, self, :eager => true )  
    end

    def source_uri_for_spec( spec )
      unless @source_uri_for_spec
        logger.info "Creating reverse index of spec -> uri"
        h = {}
        @sources.each_pair do |uri, src|
          src.source_index.gems.each_pair do |name, s|
            #logger.debug "name = #{name}, spec.full_name = #{s.full_name}"
            h[ s.full_name ] = uri
          end
        end
        @source_uri_for_spec = h
      end
      logger.debug "#{spec.full_name} has source_uri #{@source_uri_for_spec[ spec.full_name ]}"
      return @source_uri_for_spec[ spec.full_name ]
    end

    def full_uri_for_spec( spec )
      URI.join( source_uri_for_spec( spec ), "gems/#{spec.full_name}.gem" )
    end

    def sources
      @sources.values
    end

    def search( dependency )
      results = []
      @sources.each_pair do |uri, src|
        results << src.search( dependency )
      end
      results.flatten
    end

    def install( spec )
      installer.install( spec )
    end

    def remove_source( source_uri )
      if src = @sources.delete( source_uri ) then
        logger.info "destroyed #{source_uri}"
        src.destroy!
      end
    end
  end
end
