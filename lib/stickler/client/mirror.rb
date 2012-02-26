module Stickler
  class Client
    class Mirror < Stickler::Client
      def self.banner
<<-_
Pull a specific version of a gem from an upstream gem server
and store it in a stickler server.

Usage: stickler mirror [options] --gem-version x.y.z gem

  Options:
_
      end

      def parser
        unless @parser then
          @parser = super
          @parser.opt( :upstream, "The upstream gem server from which to pull", :type => :string, :default => Client.config.upstream )
          @parser.opt( :gem_version,  "The version of the gem to yank (required)",  :type => :string, :required => true )
          @parser.opt( :platform, "The platform of the gem to yank", :type => :string, :default => ::Gem::Platform::RUBY )
        end
        return @parser
      end

      def parse( argv )
        gem_name = nil
        opts = super( argv ) do |p|
          raise Trollop::CommandlineError, "At least one gem is required to mirror" if p.leftovers.empty?
          gem_name = p.leftovers.shift
        end
        opts[:gem_name] = gem_name
        return opts
      end

      def resource_uri( opts )
        opts[:server] || Client.config.server
      end

      def remote_repo_for( opts )
        Stickler::Repository::RemoteMirror.new( opts[:server], :debug => opts[:debug] )
      end

      def run
        opts = parse( self.argv )
        repo = remote_repo_for( opts )
        spec = Stickler::SpecLite.new( opts[:gem_name], opts[:gem_version], opts[:platform] )
        upstream_host = Addressable::URI.parse( opts[:upstream] ).host

        $stdout.write "Asking #{repo.uri} to mirror #{spec.full_name} from #{upstream_host} : "
        $stdout.flush

        resp = repo.mirror( spec, upstream_host )

        $stdout.puts "OK -> #{repo.uri.join(resp.headers['Location'])}"
      rescue Stickler::Repository::Error => e
        $stdout.puts "ERROR: #{e.message}"
      rescue StandardError => e
        puts e.backtrace.join("\n")
        $stdout.puts "ERROR -> #{e.message}"
     end
    end
  end
end
