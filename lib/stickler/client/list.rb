module Stickler
  class Client
    class List < Stickler::Client
      def self.banner
<<-_
List the gems in the stickler server with repository information.

Usage: stickler list

  Options:
_
      end

      def run
        opts = parse( self.argv )
      end
   end
  end
end
