require 'addressable/uri'

module Stickler::Repository
  #
  # When talking to rubygems itself, the rubygems_api key is required.
  # This authenticator is injected automatically if the host you are
  # talking to matches the rubygems host
  #
  class RubygemsAuthenticator
    def self.rubygems_uri
      @rubygems_uri ||= Addressable::URI.parse( "https://rubygems.org" )
    end

    def credentials
      Gem.configuration.rubygems_api_key
    end

    def rubygems_uri
      self.class.rubygems_uri
    end

    def handles?( scheme, host )
      return ( scheme == rubygems_uri.scheme ) &&
             ( host   == rubygems_uri.host )
    end
  end
end
