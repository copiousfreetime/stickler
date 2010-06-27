require 'resourceful'
require 'stickler/repository'
require 'stickler/repository/api'
require 'stringio'

module ::Stickler::Repository
  #
  # A Repository::Api implementation that retrieves all is data from an HTTP
  # based remote location.  It utilizes the Modern gem server api and the gem
  # cutter api (push/yank/unyank).  The legacy gem server api is not utilized.
  #
  class Remote
    # the http client
    attr_reader :http

    def initialize( repo_uri )
      @uri        = Addressable::URI.parse( ensure_trailing_slash( repo_uri ) )
      @http       = Resourceful::HttpAccessor.new( :cache_manager => Resourceful::InMemoryCacheManager.new ,
                                                   :logger => Resourceful::StdOutLogger.new)
      @specs_list = nil
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
    # The array of specs from upstream
    #
    def specs_list
      Marshal.load( download_specs_list )
    end

    #
    # See Api#search_for
    #
    def search_for( spec )
     found = []
      specs_list.each do |name, version, platform|
        up_spec = Stickler::SpecLite.new( name, version, platform )
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
      raise Stickler::Repository::Error, "gem #{spec.full_name} already exists in remote repository" if remote_gem_file_exist?( spec )
      begin
        push_resource.post( IO.read( path ) )
      rescue Resourceful::UnsuccessfulHttpRequestError => e
        msg = "Failure pushing #{path} to remote repository : response code => #{e.http_response.code}, response message => '#{e.http_response.body}'"
        raise Stickler::Repository::Error, msg
      end
      return spec
    end

    #
    # See Api#yank
    #
    def yank( spec )
      return nil unless remote_gem_file_exist?( spec )
      begin
        form_data = Resourceful::UrlencodedFormData.new
        form_data.add( "gem_name", spec.name )
        form_data.add( "version", spec.version.to_s )
        puts "form_data : #{form_data.read}"
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
        return true
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

    def specs_list_uri
      Addressable::URI.join( uri, "specs.#{Gem.marshal_version}.gz" )
    end

    def specs_list_resource
      @specs_list_resource ||= @http.resource( specs_list_uri )
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

    def download_specs_list
      download_gzipped_resource( specs_list_resource )
    end

    def download_gzipped_resource( resource )
      Gem.gunzip( download_resource( resource ) )
    end

    def download_gem( spec )
      download_uri( full_uri_to_gem( spec ) )
    end

    def download_uri( uri )
      download_resource( http.resource( uri ) )
    end

    def download_resource( resource )
      begin
        resource.get.body
      rescue Resourceful::UnsuccessfulHttpRequestError => e
        return false
      end
    end

    def remote_gem_file_exist?( spec )
      gem_uri = full_uri_to_gem( spec )
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
