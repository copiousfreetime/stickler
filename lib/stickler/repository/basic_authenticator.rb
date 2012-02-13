require 'addressable/uri'

module Stickler::Repository
  #
  # Generate the authentication for basic auth request
  #
  class BasicAuthenticator
    def self.handles?( uri )
      %w[ http https ].include?( uri.scheme ) and uri.user and uri.password
    end

    def initialize( uri )
      @user     = uri.user
      @password = uri.password
      @cred     = ["#{@user}:#{@password}"].pack('m').tr("\n", '')
    end

    def credentials
      "Basic #{@cred}"
    end
  end
end
