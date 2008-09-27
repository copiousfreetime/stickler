require 'uri'
require 'base64'
require 'progressbar'
require 'zlib'

module Stickler
  #
  # The representation of an upstream source from which stickler pulls gems.
  # This wraps up the contents of the upstream specs.4.8 file found in a
  # rubygems 1.2 or greater repository.
  #
  class Source
    class Error < ::StandardError; end

    # the uri of the source
    attr_reader :uri

    # the source_group this source belongs to
    attr_accessor :source_group

    def self.normalize_uri( uri )
      return uri if uri.kind_of?( URI::Generic ) 
      path_parts = uri.split( "/" )
      uri = path_parts.join( "/" ) + "/"
      uri = ::URI.parse( uri )
    end

    #
    # Create a new Source for a source_group.
    # Try and load the source from the cache if it can and if not, 
    # load it from the uri
    #
    def initialize( uri, source_group )

      begin
        @uri = Source.normalize_uri( uri )
        @source_group = source_group
        load_source_specs

      rescue ::URI::Error => e
        raise Error, "Unable to create source from uri #{uri} : #{e}"
      end
    end

    #
    # find all matching gems and return their SpecLite
    #
    def search( dependency )
      found = source_specs.select do | spec |
        dependency =~ Gem::Dependency.new( spec.name, spec.version )
      end
    end

    #
    # load the upstream or cached specs.marshalversion file for the source.
    #
    def source_specs
      unless @source_specs
        Console.info " * loading #{uri}" 
        @source_specs = []
        ::Gem::SpecFetcher.fetcher.load_specs( uri, 'specs' ).each do |name, version, platform|
          @source_specs << SpecLite.new( name, version, platform )
        end
      end
      return @source_specs
    end

    #
    # force a load of the source_specs
    #
    def load_source_specs
      @source_specs = nil
      return source_specs
    end
  end
end
