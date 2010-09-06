require 'trollop'
module Stickler
  class Client
    class Push < Stickler::Client
      def self.banner
<<-_
Push one or more gems to a gemserver.

Usage: stickler push [options] gemfile(s)

  Options:
_
      end

      def parse( argv )
        gemfiles = []
        opts = super do |p|
          raise Trollop::CommandlineError, "At least one file is required to push" if p.leftovers.empty?
          p.leftovers.each do |gemfile|
            raise Trollop::CommandlineError, "#{gemfile} must be readable" unless File.readable?( gemfile )
            gemfiles << File.expand_path( gemfile )
          end
        end
        opts[:gemfiles] = gemfiles
        return opts
      end

      def run
        opts = parse( self.argv )
        repo = remote_repo_for( opts )

        width = opts[:gemfiles].collect { |g| g.length }.sort.last

        puts "Pushing gem(s) to #{repo.uri} ..."
        opts[:gemfiles].each do |gemfile|
          begin
            $stdout.write "  #{gemfile.ljust( width )} -> "
            $stdout.flush
            spec = repo.push( gemfile )
            ok_msg = "OK"
            ok_msg += " #{repo.uri_for_gem( spec )}"
            $stdout.puts ok_msg
          rescue Stickler::Repository::Error => e
            $stdout.puts "ERROR: #{e.message}"
          end
        end
      end
    end
  end
end
