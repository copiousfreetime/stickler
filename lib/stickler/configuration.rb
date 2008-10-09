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

    # The gem and version requirements for this repository
    def gem_dependencies
      unless @gem_dependencies
        @gem_dependencies = []
        if hash['gems'] then
          hash['gems'].each do |name, reqs|
            [ reqs ].flatten.each do |req|
              @gem_dependencies << ::Gem::Dependency.new( name, req )
            end
          end
        end
      end
      return @gem_dependencies
    end

    def write
      File.open( config_file_name, 'w' ) do |f|
        g = Hash.new { |h,k| h[k] = [] }
        gem_dependencies.each do |d|
          g[d.name] << d.requirement_list
          g[d.name].flatten!
        end
        hash['gems'] = g
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
