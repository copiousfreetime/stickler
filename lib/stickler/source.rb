require 'uri'
require 'rubygems/source_index'
require 'base64'
require 'progressbar'
require 'zlib'

module Stickler
  #
  # The representation of an upstream source from which stickler pulls gems.
  # This wraps up a Gem::SourceIndex along with some other meta information
  # about the source.
  #
  class Source
    class Error < ::StandardError; end

    # the uri of the source
    attr_reader :uri

    # stats from the upstream webserver
    attr_reader :upstream_stats

    # the source_group this source belongs to
    attr_accessor :source_group

    class << self
      #
      # Upstream headers to be used to detect if an upstream Marshal is okay
      #
      def cache_detection_headers
        %w[ etag last-modified content-length ]
      end

      # 
      # The name of a marshaled file for a given uri
      #
      def marshal_file_name_for( uri )
        encoded_uri = Base64.encode64( uri ).strip
        return "#{encoded_uri}.Marshal.#{Gem.marshal_version}"
      end

      #
      # load a source from a cache file if it exists, otherwise
      # load it the normal way
      #
      def load( uri, source_group )
        cache_dir = source_group.cache_dir
        cache_file = File.join( cache_dir, marshal_file_name_for( uri ) )
        if File.exist?( cache_file ) then
          source_group.logger.debug "Loading #{uri} from cache"
          source = Marshal.load( IO.read( cache_file ) )
          source.source_group = source_group
        else
          source = Source.new( uri, source_group )
        end
        return source
      end
    end

    #
    # Create a new Source for a source_group.
    # Try and load the source from the cache if it can and if not, 
    # load it from the uri
    #
    def initialize( uri, source_group )
      begin
        @uri = uri 
        ::URI.parse( uri ) # make sure it is valid

        @source_group = source_group
        @upstream_stats = {}

      rescue ::URI::Error => e
        raise Error, "Unable to create source from uri #{uri} : #{e}"
      end
    end

    #
    # the local cache directory where the serialized version of this source is
    # held
    #
    def cache_dir
      source_group.cache_dir
    end

    def my_marshal_file_name
      Source.marshal_file_name_for( uri )
    end

    def logger
     ::Logging::Logger[self]
    end

    #
    # The predictable URI of the compressed Marshal file on the upstream gem
    # server.
    #
    def upstream_marshal_uri
      URI.join( uri, "Marshal.#{Gem.marshal_version}.Z" ).to_s
    end

    #
    # get the http response and follow redirection 
    #
    def fetch( method, uri, limit = 10 )
      response = nil
      while limit > 0
        uri = URI.parse( uri ) 
        logger.debug " -> #{method.upcase} #{uri}"
        connection = Net::HTTP.new( uri.host, uri.port )
        response = connection.send( method, uri.path )
        logger.debug " <- #{response.code} #{response.message}"
        case response
        when Net::HTTPSuccess then break
        when Net::HTTPRedirection then 
          uri = response['location']
          limit -= 1
        else 
          response.error!
        end
      end
      raise Error, "HTTP redirect to #{path} too deep" if limit == 0
      return response
    end
   
    #
    # shortcut for the latests specs
    #
    def latest_specs
      source_index.latest_specs
    end

    #
    # Access its source_index
    #
    def source_index
      return @source_index if source_index_same_as_upstream?
      load_source_index_from_upstream
      return @source_index
    end

    #
    # load the source index member variable from the upstream source
    #
    def load_source_index_from_upstream
      response = fetch( 'get', upstream_marshal_uri )
      inflated = Zlib::Inflate.inflate( response.body )
      begin
        @source_index = Marshal.load( inflated ) 
        save!
      rescue => e
        Console.error e.backtrace.join("\n")
        raise Error, "Corrupt upstream source index of #{upstream_marshal_uri} : #{e}"
      end
      return @source_index
    end

    #
    # return true if the current source_index is the same as the upstream
    # source_index as indicated by the HTTP headers
    def source_index_same_as_upstream? 
      logger.debug "Checking if our our cached version of #{uri} is up to date"
      response = fetch( 'head', upstream_marshal_uri )

      Source.cache_detection_headers.each do |key|
        unless response[key].nil?
          if upstream_stats[key] == response[key] then
            logger.debug "  our cache is up to date ( #{key} : #{response[key]} )"
            return true
          else
            upstream_stats[key] = response[key]
          end
        end
      end
      logger.debug "  our cache is NOT up to date"
      return false
    end

    # 
    # The name of this source serialized as a marshaled object
    #
    def cache_file_name
      @cache_file_name ||= File.join( cache_dir, "#{my_marshal_file_name}" )
    end

    #
    # save self as a marshalled file to the cache file name
    #
    def save!
      logger.info "Writing source #{uri} to #{cache_file_name}"
      before_save_group = @source_group
      @source_group = nil
      File.open( cache_file_name, "wb" ) do |f|
        Marshal.dump( self, f )
      end
      @source_group = before_save_group
    end

    #
    # Destroy self and all gems that come from me
    #
    def destroy!
      logger.info "Destroying source #{uri} cache file #{cache_file_name}"
      FileUtils.rm_f cache_file_name
      Console.error " Still need to delete the gems from this source"
    end
  end
end
