require 'rubygems/platform'
require 'rubygems/version'

module Stickler
  #
  # A lightweight version of a gemspec that only responds to name, version,
  # platform and full_name.  Many of the items in the rubygems world
  # deal with the triplet [ name, verison, platform ] and this class
  # encapsulates that.
  #
  class SpecLite
    include Comparable

    attr_reader :name
    attr_reader :version
    attr_reader :platform
    attr_reader :platform_string

    def initialize( name, version, platform = Gem::Platform::RUBY )
      @name = name
      @version = Gem::Version.new( version )
      @platform_string = platform.to_s
      @platform = Gem::Platform.new( platform )
    end

    def full_name
      "#{name}-#{version_platform}"
    end
    alias :to_s :full_name

    def file_name
      full_name + ".gem"
    end

    def spec_file_name
      full_name + ".gemspec"
    end

    def name_version
      "#{name}-#{version}"
    end

    def version_platform
      if platform == Gem::Platform::RUBY or platform.nil? then
        version.to_s
      else
        "#{version}-#{platform_string}"
      end
    end

    def to_a
      [ name, version.to_s, platform_string ]
    end

    # 
    # Convert to the array format used by rubygems itself
    #
    def to_rubygems_a
      [ name, version, platform_string ]
    end

    #
    # Lets be comparable!
    #
    def <=>(other)
      return 0 if other.object_id == self.object_id
      other = coerce( other )

      [ :name, :version, :platform_string ].each do |method|
        us, them = self.send( method ), other.send( method )
        result = us.<=>( them )
        return result unless 0 == result
      end

      return 0
    end

    #
    # See if another Spec is the same as this spec
    #
    def =~(other)
      other = coerce( other )
      return (other and 
              self.name == other.name and
              self.version.to_s == other.version.to_s and
              self.platform_string == other.platform_string )
    end

    private

    def coerce( other )
      if self.class === other then
        other
      elsif other.respond_to?( :name ) and 
            other.respond_to?( :version ) and 
            other.respond_to?( :platform_string ) then
        SpecLite.new( other.name, other.version, other.platform_string )
      else
        return false
      end
    end
  end
end
