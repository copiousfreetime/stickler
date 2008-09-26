require 'ostruct'
require 'open-uri'

module Stickler
  #
  # A class that fetches gems and all its dependencies from a series of remote
  # sources and installs them into the appropriate locations in the Repository.
  #
  class Installer

    class Error < StandardError ; end

    # The SourceGroup this installers belongs to
    attr_reader :source_group

    def initialize( source_group )
      @source_group = source_group
      @fetcher = ::Gem::RemoteFetcher.new( nil )
    end

    def logger
      @logger ||= ::Logging::Logger[self]
    end

    private

 end
end

