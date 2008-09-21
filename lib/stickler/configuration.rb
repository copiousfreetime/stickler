module Stickler
  #
  # Configuration implements all the accessor methods of Gem::ConfigFile so it
  # can be used in place of Gem::ConfigFile in Gem.configuration.  The comments
  # on these methods are the same as those in Gem::ConfigFile
  #
  class Configuration

    attr_reader :config_file_name

    def initialize( config_file_name )
      @config_file_name = config_file_name
      @hash = YAML.load_file( config_file_name )
    end

    # the array of sources in this configuration
    def sources
      hash['sources']
    end

    # the downstream source  this repository represents
    def downstream_source
      hash['downstream_source']
    end

    # True if the backtrace is on
    def backtrace
      hash['backtrace'] or $DEBUG
    end

    # is the run being benchmarked
    def benchmark
      false
    end

    # Bulk threshold value.   If the number of missing gems are above this
    # threshold value, then buld download technique is used
    def bulk_threshold
      hash['bulk_threshold']
    end

    # Verbose level of output
    # * false -- No output
    # * true -- Normal output
    # * :loud -- Extra output
    def verbose
      hash['verbose']
    end

    # True if we want to update the SourceInfoCache every time, false otherwise
    def update_sources
      hash['update_sources']
    end

    # Really verbose mode gives you extra output
    def really_verbose
      case verbose
      when true, false, nil then false
      else true
      end
    end

    def write
      File.open( config_file_name, 'w' ) do |f|
        f.write hash.to_yaml
      end
    end

    def keys
      @hash.keys
    end

    def []( key )
      @hash[ key.to_s ]
    end

    def []=( key, value )
      @hash[ key.to_s ] = value
    end

    def ==( other )
      self.class === other and hash == other.hash
    end

    protected
    attr_reader :hash
  end
end
