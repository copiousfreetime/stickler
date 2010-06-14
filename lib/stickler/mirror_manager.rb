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
    end

    def for( mirror_name )
      if not mirrors.has_key?( mirror_name ) then
        mirrors[mirror_name] = Mirror.new( root_dir, mirror_name )
      end
      return mirrors[mirror_name]
    end
  end
end
