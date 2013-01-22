module Stickler
  class Client
    class Unyank < Stickler::Client
      def self.banner
<<-_
Restore a yanked gem to the gemserver's index.  

Usage: stickler unyank [options] --gem-version x.y.z gem

  Options:
_
      end

      def parser
        unless @parser then
          @parser = super
          @parser.opt( :gem_version,  "The version of the gem to unyank (required)",  :type => :string, :required => true )
          @parser.opt( :platform, "The platform of the gem to unyank", :type => :string, :default => ::Gem::Platform::RUBY )
        end
        return @parser
      end

      def parse( argv )
        gem_name = nil
        opts = super( argv ) do |p|
          raise Trollop::CommandlineError, "At least one gem is required to unyank" if p.leftovers.empty?
          gem_name = p.leftovers.shift
        end
        opts[:gem_name] = gem_name
        return opts
      end

      def run
        opts = parse( self.argv )
        repo = remote_repo_for( opts )
        spec = Stickler::SpecLite.new( opts[:gem_name], opts[:gem_version], opts[:platform] )

        $stdout.write "Unyanking gem #{spec.full_name} from #{repo.uri} : "
        $stdout.flush
        if spec = repo.unyank( spec ) then
          $stdout.puts "OK"
        else
          $stdout.puts "FAILURE"
        end
     rescue Stickler::Repository::Error => e
        $stdout.puts "ERROR: #{e.message}"
     end
    end
  end
end
