require 'excon'
require 'stickler/repository'
require 'stickler/repository/api'
require 'stickler/repository/rubygems_authenticator'
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

    def initialize( repo_uri, options = {}   )
      options[:authenticator] ||= Stickler::Repository::RubygemsAuthenticator.new

      @uri        = Addressable::URI.parse( ensure_http( ensure_trailing_slash( repo_uri ) ) )
      @http       = Excon.new( @uri.to_s )
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
      resp = push_resource.request( :method => :post,  :body => IO.read( path ), :expects => [ 200 ] )
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
      response = yank_resource.request( :method => :delete, :query => query, 
                                        :headers => {'Content-Type' => 'application/x-www-form-urlencoded'},
                                        :expects => [200])
      return full_uri_to_gem( spec )
    rescue Excon::Errors::Error => e
      raise Stickler::Repository::Error, "Failure yanking: #{e.inspect}"
    end

    #
    # See Api#delete
    #
    def delete( spec )
      return false unless remote_gem_file_exist?( spec )
      gem_resource( spec ).request( :method => :delete )
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

    def full_uri_to_gem( spec )
      gems_uri.join( spec.file_name )
    end

    def specs_list_uri
      Addressable::URI.join( uri, "specs.#{Gem.marshal_version}.gz" )
    end

    def specs_list_resource
      @specs_list_resource ||= Excon.new( specs_list_uri.to_s )
    end

    def push_uri
      Addressable::URI.join( uri, "api/v1/gems" )
    end

    def push_resource
      @push_resource ||= Excon.new( push_uri.to_s, :headers => { 'Content-Type' => 'application/octet-stream' } )
    end

    def yank_uri
      Addressable::URI.join( uri, "api/v1/gems/yank" )
    end

    def yank_resource
      @yank_resource ||= Excon.new( yank_uri.to_s )
    end

    def gem_resource( spec )
      Excon.new( full_uri_to_gem( spec ) )
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
      resource.request( :method => :get ).body
    rescue Excon::Errors::Error => e
      return false
    end

    def remote_gem_file_exist?( spec )
      gem_uri = full_uri_to_gem( spec )
      remote_uri_exist?( gem_uri )
    end

    def remote_uri_exist?( uri )
      rc = Excon.head( uri.to_s, :expects => [ 200, 301, 302] )
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
  end
end
