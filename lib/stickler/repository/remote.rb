require 'resourceful'
require 'stickler/repository'
require 'stickler/repository/api'
require 'stringio'

module ::Stickler::Repository
  #
  # A Repository::Api implementation that retrieves all is data from an HTTP
  # based remote location.
  #
  class Remote
    # the http client
    attr_reader :http

    def initialize( repo_uri )
      @uri          = Addressable::URI.parse( ensure_trailing_slash( repo_uri ) )
      @http         = ::Resourceful::HttpAccessor.new( :cache_manager => Resourceful::InMemoryCacheManager.new )
      @source_index = nil
    end

    #
    # See Api#uri
    def uri
      @uri
    end

    #
    # See Api#gems_uri
    #
    def gems_uri
      @gems_uri ||= self.uri.join( "gems/" )
    end

    #
    # See Api#uri_from_gem
    #
    def uri_for_gem( spec )
      return nil unless remote_gem_file_exist?( spec )
      return self.gems_uri.join( spec.file_name )
    end

    #
    # See Api#source_index
    #
    def source_index
      Marshal.load( download_source_index )
    end

    #
    # See Api#search_for
    #
    def search_for( spec )
     found = []
      source_index.each do |name, version, platform|
        up_spec = SpecLite.new( name, version, platform )
        found << up_spec if spec =~ up_spec
      end
      return found
    end

    #
    # See Api#get
    #
    def get( spec )
      return download_gem( spec ) if remote_gem_file_exist?( spec )
      return nil
    end

    #
    # See Api#push
    #
    def push( path )
      spec = speclite_from_gem_file( path )
      raise Stickler::Repository::Error, "it already exists" if remote_gem_file_exist?( spec )
      begin
        push_resource.post( IO.read( path ) )
      rescue Resourceful::UnsuccessfulHttpRequestError => e
        raise Stickler::Repository::Error, "Failure pushing: #{e.inspect}"
      end
      return spec
    end

    #
    # See Api#yank
    #
    def yank( spec )
      return nil unless remote_gem_file_exist?( spec )
      begin
        form_data = Resourcefule::URLEncodedFormData.new
        form_data.add( "gem_name", spec.name )
        form_data.add( "version", spec.version )
        yank_resource.request( :delete, form_data.read, {'Content-Type' => form_data.content_type } )
      rescue Resourceful::UnsuccessfulHttpRequestError => e
        raise Stickler::Repository::Error, "Failure yanking: #{e.inspect}"
      end
    end

    #
    # See Api#delete
    #
    def delete( spec )
      return false unless remote_gem_file_exist?( spec )
      begin
        gem_resource( spec ).delete
      rescue Resourceful::UnsuccessfulHttpRequestError => e
        return false
      end
    end

    #
    # See Api#open
    #
    def open( spec, &block )
      return nil unless remote_gem_file_exist?( spec )
      begin
        resp = gem_resource( spec ).get
        io = StringIO.new( resp.body, "rb" )
        if block_given? then
          begin
            yield io
          ensure
            io.close
          end
        else
          return io
        end
      rescue Resourceful::UnsuccessfulHttpRequestError => e
        return nil
      end
      nil
    end

    private

    def ensure_trailing_slash( uri )
      uri += '/' unless uri =~ %r{/\Z}
      return uri
    end

    def full_uri_to_gem( spec )
      gems_uri.join( spec.file_name )
    end

    def source_index_uri
      Addressable::URI.join( uri, "specs.#{Gem.marshal_version}.gz" )
    end

    def source_index_resource
      @source_index_resource ||= @http.resource( source_index_uri )
    end

    def push_uri
      Addressable::URI.join( uri, "api/v1/gems" )
    end

    def push_resource
      @push_resource ||= @http.resource( push_uri, { 'Content-Type', 'application/octet-stream' } )
    end

    def yank_uri
      Addressable::URI.join( uri, "api/v1/gems/yank" )
    end

    def yank_resource
      @yank_resource ||= @http.resource( yank_uri )
    end

    def gem_resource( spec )
      @http.resource( full_uri_to_gem( spec ) )
    end

    def download_source_index
      download_gzipped_resource( source_index_resource )
    end

    def download_gzipped_resource( resource )
      resp = download( resource )
      Gem.gunzip( resp.body )
    end

    def download_gem( spec )
      download_uri( full_uri_to_gem( spec ) )
    end

    def download_uri( uri )
      begin
        http.resource( uri ).get
      rescue Resourceful::UnsuccessfulHttpRequestError => e
        return false
      end
    end

    def remote_gem_file_exist?( spec )
      gem_uri = full_uri_to_gem( spec )
      puts "gem_uri : #{gem_uri.to_s}"
      remote_uri_exist?( gem_uri )
    end

    def remote_uri_exist?( uri )
      begin
        http.resource( uri ).head.successful?
      rescue Resourceful::UnsuccessfulHttpRequestError => e
        return false
      end
    end

    def speclite_from_gem_file( path )
      speclite_from_specification( specification_from_gem_file( path ) )
    end

    def specification_from_gem_file( path )
      format = Gem::Format.from_file_by_path( path )
      return format.spec
    end

    def speclite_from_specification( spec )
      Stickler::SpecLite.new( spec.name, spec.version.to_s, spec.platform )
    end
  end
end
