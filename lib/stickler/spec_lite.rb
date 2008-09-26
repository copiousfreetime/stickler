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
      @version = version
      @new_platform = Gem::Platform.new( platform )
      @platform = platform
    end

    def full_name
      if platform == Gem::Platform::RUBY or platform.nil? then
        "#{name}-#{version}"
      else
        "#{name}-#{version}-#{platform}"
      end
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
  end
end

module Gem
  class Specification
    def name_version
      "#{name}-#{version}"
    end
  end
end
