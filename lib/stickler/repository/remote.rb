require 'excon'
require 'stickler'
require 'stickler/repository'
require 'stickler/repository/api'
require 'stickler/repository/rubygems_authenticator'
require 'stickler/repository/basic_authenticator'
require 'stringio'

module ::Stickler::Repository
  #
  # A Repository::Api implementation that retrieves all is data from an HTTP
  # based remote location.  It utilizes the Modern gem server api and the gem
  # cutter api (push/yank/unyank).  The legacy gem server api is not utilized.
  #
  class Remote

    attr_reader :authenticator

    def initialize( repo_uri, options = {}   )
      @uri           = Addressable::URI.parse( ensure_http( ensure_trailing_slash( repo_uri ) ) )
      @authenticator = load_authenticator( @uri )
      @specs_list    = nil
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
      resp = resource_request( push_resource, :body => IO.read( path ) )
      return spec
    rescue Excon::Errors::Error => e
      msg = "Failure pushing #{path} to remote repository : response code => #{e.response.status}, response message => '#{e.response.body}'"
      raise Stickler::Repository::Error, msg
    end

    #
    # See Api#yank
    #
    def yank( spec )
      return nil unless remote_gem_file_exist?( spec )
      query = { :gem_name => spec.name, :version => spec.version.to_s }
      resp  = resource_request( yank_resource, :query => query  )
      return full_uri_to_gem( spec )
    rescue Excon::Errors::Error => e
      raise Stickler::Repository::Error, "Failure yanking: #{e.inspect}"
    end

    #
    # See Api#unyank
      #
    def unyank( spec )
      return nil unless remote_gem_file_exist?( spec )
      query = { :spec_name => spec.name, :version => spec.version.to_s }
      resp  = resource_request( unyank_resource, :query => query  )
      true
    rescue Excon::Errors::Error => e
      # raise Stickler::Repository::Error, "Failure unyanking: #{e.inspect}"
      []
    end

    #
    # See Api#delete
    #
    def delete( spec )
      return false unless remote_gem_file_exist?( spec )
      resource_request( gem_resource( spec ), :method => :delete )
      return true
    rescue Excon::Errors::Error => e
      return false
    end

    #
    # See Api#open
    #
    def open( spec, &block )
      return nil unless remote_gem_file_exist?( spec )
      data = download_resource( gem_resource( spec ) )
      io = StringIO.new( data , "rb" )
      if block_given? then
        begin
          yield io
        ensure
          io.close
        end
      else
        return io
      end
      nil
    rescue Excon::Errors::Error => e
      $stderr.puts e.inspect
      return nil
    end

    private

    def ensure_trailing_slash( uri )
      uri += '/' unless uri =~ %r{/\Z}
      return uri
    end

    def ensure_http( uri )
      uri = "http://#{uri}" unless uri =~ %r{\Ahttp(s)?://}
      return uri
    end

    def authenticator_class( uri )
      [ RubygemsAuthenticator, BasicAuthenticator ].find { |a| a.handles?( uri ) }
    end

    def load_authenticator( uri )
      if klass = authenticator_class( uri ) then
        return klass.new( uri )
      end
      return nil
    end

    def full_uri_to_gem( spec )
      gems_uri.join( spec.file_name )
    end

    def specs_list_uri
      Addressable::URI.join( uri, "specs.#{Gem.marshal_version}.gz" )
    end

    def specs_list_resource
      @specs_list_resource ||= Excon.new( specs_list_uri.to_s, :method => :get, :expects => [200] )
    end

    def push_uri
      Addressable::URI.join( uri, "api/v1/gems" )
    end

    def push_resource
      unless @push_resource then
        params = { :method => :post, :headers => { 'Content-Type' => 'application/octet-stream' }, :expects => [ 201, 200 ] }
        @push_resource = Excon.new( push_uri.to_s, params )
      end
      return @push_resource
    end

    def yank_uri
      Addressable::URI.join( uri, "api/v1/gems/yank" )
    end

    def unyank_uri
      Addressable::URI.join( uri, "api/v1/gems/unyank" )
    end

    def yank_resource
      unless @yank_resource then
        params = { :method => :delete,
                   :headers => { 'Content-Type' => 'application/x-www-form-urlencoded' },
                   :expects => [200] }
        @yank_resource = Excon.new( yank_uri.to_s, params )
      end
      return @yank_resource
    end
    
    def unyank_resource
      unless @unyank_resource then
        params = { :method => :post,
                   :headers => { 'Content-Type' => 'application/x-www-form-urlencoded' },
                   :expects => [200] }
        @unyank_resource = Excon.new( unyank_uri.to_s, params )
      end
      return @unyank_resource
    end

    def gem_resource( spec )
      Excon.new( full_uri_to_gem( spec ), :method => :get, :expects => [200] )
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
      download_resource( Excon.new( uri ) )
    end

    def download_resource( resource )
      resource_request( resource, :method => :get, :expects => [200] ).body
    rescue Excon::Errors::Error => e
      $stderr.puts e.inspect
      return false
    end

    def remote_gem_file_exist?( spec )
      gem_uri = full_uri_to_gem( spec )
      remote_uri_exist?( gem_uri )
    end

    def remote_uri_exist?( uri )
      rc = resource_request( Excon.new( uri.to_s ),  :method => :head, :expects => [200] )
      return true
    rescue Excon::Errors::Error => e
      return false
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

    def resource_request( resource, params = {} )
      trys = 0
      begin
        resource.connection[:headers]['User-Agent'] = "Stickler Client v#{Stickler::VERSION}"
        resource.connection[:headers].delete('Authorization')
        if authenticator then
          resource.connection[:headers]['Authorization'] = authenticator.credentials
        end
        trys += 1
        resource.request( params )
      rescue Excon::Errors::Unauthorized => unauth
        uri = "#{unauth.request[:scheme]}://#{unauth.request[:host]}:#{unauth.request[:port]}#{unauth.request[:path]}"
        raise Stickler::Repository::Error, "Not authorized to access #{uri}. Authorization needed for: #{unauth.response.headers['WWW-Authenticate']}"
      rescue Excon::Errors::MovedPermanently, Excon::Errors::Found,
             Excon::Errors::SeeOther, Excon::Errors::TemporaryRedirect => redirect
        # follow a redirect, it is only allowable to follow redirects from a GET or
        # HEAD request.  Only follow a few times though.
        raise redirect unless [ :get, :head ].include?( redirect.request[:method] )
        raise redirect if trys > 5
        resource = Excon::Connection.new( redirect.response.headers['Location'],
                                          { :headers => resource.connection[:headers],
                                            :query   => resource.connection[:headers],
                                            :method  => resource.connection[:method] } )
        retry
      end
    end
  end
end
