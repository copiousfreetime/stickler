module Stickler
  class Client
    class Version < Stickler::Client
      def self.banner
        <<-_
List the gems in the stickler server with repository information.

Usage: stickler list

  Options:
        _
      end

      def run
        begin
          raise Stickler::Repository::Error, 'last-version option needs an argument (gem name)' if self.argv.first.nil?
          opts = parse(self.argv)
          repo = remote_repo_for(opts)
          hashversions = {}
          repo.specs_list.each do |name, version|
            hashversions.store(name, "#{version}")
          end
          lastversion = hashversions[self.argv.first]
          raise Stickler::Repository::Error, 'Gem doesn\'t exist in the server.' if lastversion.nil?
          puts lastversion
          return lastversion
        rescue Stickler::Repository::Error => e
          $stdout.puts "ERROR: #{e.message}"
        end
      end
    end
  end
end
