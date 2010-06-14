require 'stickler/mirror'
module Stickler
  # The mirror manager, well it manages mirrors.  All mirrors are
  # in a directory below the manager's root directory
  class MirrorManager

    # The top level directory under which all mirrors are stored
    attr_reader :root_dir

    # The list of known mirrors keyed by name
    attr_reader :mirrors

    def initialize( root_dir ) 
      @root_dir  = File.expand_path( root_dir )
      @mirrors   = Hash.new
      if File.directory?( root_dir ) then
        load_mirrors
      else
        FileUtils.mkdir_p( root_dir )
      end
    end

    def load_mirrors
      Dir.entries( root_dir ).each do |entry|
        entry_dir = File.join( root_dir, entry )
        next unless File.directory?( entry_dir )
        next if entry =~ /\A\./
        if File.directory?( File.join( entry_dir, 'specifications' ) ) then
          self.for( entry )
          puts "Loaded mirror #{entry}"
        end
      end
    end

    def gem_path
      mirrors.values.collect do |m|
        m.root_dir
      end
    end

    def for( mirror_name )
      if not mirrors.has_key?( mirror_name ) then
        mirrors[mirror_name] = Mirror.new( root_dir, mirror_name )
      end
      return mirrors[mirror_name]
    end
  end
end
