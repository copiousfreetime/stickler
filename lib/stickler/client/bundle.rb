require 'bundler'

module Stickler
  class Client
    class Bundle < Stickler::Client
      def self.banner
<<-_
Ask Stickler to mirror all gems defined in your Gemfile.
This task can be used for migrating to Stickler, or quickly
updating your local gem server via Bundler.

Usage: stickler bundle

  Options:
_
      end

      # ---------------------------------------------------------------------
      # Read current Gemfile via Bundler environment, then iterate
      # through Gem specs, listed in the following structure:
      # e.g. [ 'rack', [<Gem::Specification name=rack version=1.4.5>]]
      # ---------------------------------------------------------------------
      def run
        gems = Bundler.environment.specs.to_hash

        gems.collect{ |gem| gem[1][0] }.each do |gem|
          name      = gem.name
          version   = gem.version
          arguments = ['--gem-version', version, name]
          ::Stickler::Client::Mirror.new( arguments ).run
        end
      end
    end
  end
end
