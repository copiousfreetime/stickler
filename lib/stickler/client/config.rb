module Stickler
  class Client
    class Config < Stickler::Client
      def self.banner
<<-_
Access or update the Stickler client configuration.  

Usage: stickler config [options] 

  Options:
_
      end

      def parser
        unless @parser then
          @parser = super
          @parser.opt( :upstream, "The upstream gem server from which to pull", :type => :string, :default => Client.config.upstream )
          @parser.opt( :add, "Add upstream and/or server to the configuration", :type => :boolean )
          @parser.opt( :list, "display the current configuration", :type => :boolean )
        end
        return @parser
      end

      def dump_config( opts )
        puts "  server : #{Client.config.server}"
        puts "upstream : #{Client.config.upstream}"
      end

      def run
        opts = parse( self.argv )
        dump_config( opts ) if Client.config.update( opts ) || opts[:list]
      end
   end
  end
end
