module Stickler
  #
  # Wrap the class that opens the gem file and gives access to all the gem file
  # internals. The class that implements this in rubygems itself changed, so we
  # need to be backwards compatible with folks that are using older versions of
  # rubygems.
  #
  class GemContainer
    attr_reader :path
    def initialize( gem_file_path )
      @path      = gem_file_path
      @container = load_container( path )
    end

    def spec
      @container.spec
    end

    private

    # Rubygems transitions to using Gem::Package, so if we have that use it,
    # otherwise fall back to the older method of using Gem::Format
    begin
      require 'rubygems/package'
      def load_container( path )
        Gem::Package.new( path )
      end
    rescue LoadError
      puts "Unable to load 'rubygems/package' falling back to Gem::Format"
      begin
        require 'rubygems/format'
        def load_container( path )
          Gem::Format.from_file_by_path( path )
        end
      rescue LoadError
        abort "Failure to load rubygems/format"
      end
    end
  end
end
