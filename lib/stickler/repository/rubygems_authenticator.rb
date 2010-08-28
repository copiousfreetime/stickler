module Stickler::Repository
  #
  # When talking to rubygems itself, the rubygems_api key is required.
  # This authenticator is injected automatically if the host you are
  # talking to matches the rubygems host
  #
  class RubygemsAuthenticator
    def credentials
      Gem.configuration.rubygems_api_key
    end

    def rubygems_uri
      @rubygems_uri ||= Addressable::URI.parse( "https://rubygems.org" )
    end

    def can_handle?( request )
      request_uri  = Addressable::URI.parse(request.uri)
      return (request_uri.host   == rubygems_uri.host  ) && 
             (request_uri.scheme == rubygems_uri.scheme)
    end

    def add_credentials_to(request)
      request.header['Authorization'] = credentials
    end
  end
end
