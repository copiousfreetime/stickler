require 'trollop'
require 'rubygems'

module Stickler
  class Client

    attr_reader :argv
    attr_reader :sources
    attr_reader :configuration

    def initialize( argv = ARGV )
      @argv          = argv
      @configuration = Gem.configuration
    end

    def parser
      me = self # scoping forces this
      @parser ||= Trollop::Parser.new do
        banner me.class.banner
        opt :server, "The gem or stickler server URL", :type => :string, :required => true
        opt :debug, "Output debug information for the server interaction", :default => false
      end
    end

    def parse( argv )
      opts = Trollop::with_standard_exception_handling( parser ) do
        raise Trollop::HelpNeeded if argv.empty? # show help screen
        o = parser.parse( argv )
        yield parser if block_given?
        return o
      end
      return opts
    end

    def remote_repo_for( opts )
      Stickler::Repository::Remote.new( opts[:server], :debug => opts[:debug] ) 
    end
  end
end

require 'stickler/client/push'
require 'stickler/client/yank'
require 'stickler/client/mirror'
