require 'stickler/repository/remote_mirror'
module Stickler
  class Client
    class Mirror < Stickler::Client
      def self.banner
<<-_
Pull a specific version of a gem from an upstream gem server
and store it in a stickler server. Either a specific version
must be specificied, or a Gemfile.lock must be used.

Usage: stickler mirror [options] --gem-version x.y.z gem
       stickler mirror [options] Gemfile.lock

  Options:
_
      end

      def parser
        unless @parser then
          @parser = super
          @parser.opt( :upstream, "The upstream gem server from which to pull", :type => :string, :default => Client.config.upstream )
          @parser.opt( :gem_version,  "The version of the gem to mirror", :type => :string)
          @parser.opt( :platform, "The platform of the gem to mirror", :type => :string, :default => ::Gem::Platform::RUBY )
        end
        return @parser
      end

      def parse( argv )
        gem_name     = nil
        gemfile_lock = nil
        opts = super( argv ) do |p, o|
          raise Trollop::CommandlineError, "A Gemfile.lock or a gem name is required to mirror" if p.leftovers.empty?
          if o[:gem_version] then
            gem_name = p.leftovers.shift
          else
            gemfile_lock = p.leftovers.shift
            raise Trollop::CommandlineError, "#{lock} must be readable" unless File.readable?( gemfile_lock )
          end
        end
        opts[:gem_name]     = gem_name
        opts[:gemfile_lock] = gemfile_lock
        return opts
      end

      def resource_uri( opts )
        opts[:server] || Client.config.server
      end

      def remote_repo_for( opts )
        Stickler::Repository::RemoteMirror.new( opts[:server], :debug => opts[:debug] )
      end

      def spec_list( opts )
        if opts[:gem_name] then
          return [Stickler::SpecLite.new( opts[:gem_name], opts[:gem_version], opts[:platform] )]
        end

        if opts[:gemfile_lock] then
          parser = Stickler::GemfileLockParser.new( opts[:gemfile_lock] )
          return parser.gem_dependencies
        end
        raise Sticker::Error, "No gem name, or gemfile lock... no idea what to do"
      end

      def mirror_one_spec( repo, spec, upstream_host )
        $stdout.write "Asking #{repo.uri} to mirror #{spec.full_name} from #{upstream_host} : "
        $stdout.flush

        resp = repo.mirror( spec, upstream_host )
        $stdout.puts "OK -> #{repo.uri.join(resp.headers['Location'])}"

      rescue Stickler::Repository::Error => e
        $stdout.puts "ERROR: #{e.message}"
      rescue StandardError => e
        $stdout.puts e.backtrace.join("\n")
        $stdout.puts "ERROR -> #{e.message}"
      end

      def run
        opts          = parse( self.argv )
        repo          = remote_repo_for( opts )
        specs         = spec_list( opts )
        upstream_host = Addressable::URI.parse( opts[:upstream] ).host

        specs.each do |spec|
          mirror_one_spec( repo, spec, upstream_host )
        end
      rescue Stickler::Repository::Error => e
        $stdout.puts "ERROR: #{e.message}"
      rescue StandardError => e
        puts e.backtrace.join("\n")
        $stdout.puts "ERROR -> #{e.message}"
      end
    end
  end
end
