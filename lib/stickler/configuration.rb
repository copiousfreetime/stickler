module Stickler
  #
  #
  #
  class Configuration

    attr_reader :config_file_name

    def initialize( config_file_name )
      @config_file_name = config_file_name
      @hash = YAML.load_file( config_file_name )
      @hash['sources'] = @hash['sources'].collect do |uri|
        p = uri.split("/")
        p.join("/") + "/" # ensure a trailing slash
      end
    end

    # the array of sources in this configuration
    def sources
      hash['sources']
    end

    # the downstream source  this repository represents
    def downstream_source
      hash['downstream_source']
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
