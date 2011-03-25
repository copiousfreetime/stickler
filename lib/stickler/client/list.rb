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
        repo = remote_repo_for( opts )
        gems = Hash.new { |h,k| h[k] = Array.new }

        repo.specs_list.each do |name, version, platform|
          spec = Stickler::SpecLite.new( name, version, platform )
          gems[name] << spec
        end

        gems.keys.sort.each do |name|
          puts "#{name} (#{gems[name].collect { |s| s.version_platform }.join( ", " )})"
        end
      end
   end
  end
end
