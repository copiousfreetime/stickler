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

    def self.handles?( uri )
      return ( uri.scheme == rubygems_uri.scheme ) &&
             ( uri.host   == rubygems_uri.host )
    end

    def initialize( uri )
      # do nothing
    end

    def credentials
      Gem.configuration.rubygems_api_key
    end

    def rubygems_uri
      self.class.rubygems_uri
    end

  end
end
