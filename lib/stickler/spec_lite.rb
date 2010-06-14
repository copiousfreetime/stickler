module Stickler
  #
  # A lightweight version of a gemspec that only responds to name, version,
  # platform and full_name.  Many of the items in the rubygems world
  # deal with the triplet [ name, verison, platform ] and this class
  # encapsulates that.
  #
  class SpecLite
    attr_reader :name
    attr_reader :version
    attr_reader :platform

    def initialize( name, version, platform )
      @name = name
      @version = Gem::Version.new( version )
      @platform = Gem::Platform.new( platform )
    end

    def full_name
      if platform == Gem::Platform::RUBY or platform.nil? then
        "#{name}-#{version}"
      else
        "#{name}-#{version}-#{platform}"
      end
    end

    def file_name
      full_name + ".gem"
    end

    def spec_file_name
      full_name + ".gemspec"
    end

    def name_version
      "#{name}-#{version}"
    end

    def to_a
      [ name, version, platform.to_s ]
    end

    def to_s
      full_name
    end

    def =~(other)
      other = coerce( other )
      return (self.name == other.name and
              self.version == other.version and
              self.platform == other.platform )
    end

    private

    def coerce( other )
      if self.class === other then
        other
      elsif other.respond_to?( :name ) and 
            other.respond_to?( :version ) and 
            other.respond_to?( :platform ) then
        SpecLite.new( other.name, other.version, other.platform )
      else
        return false
      end
    end
  end
end
