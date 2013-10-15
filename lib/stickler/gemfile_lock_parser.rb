module Stickler
  class GemfileLockParser
    attr_reader :gem_dependencies


    def initialize( path )
      p = Pathname.new( path )
      raise Stickler::Error, "#{path} does not exist"  unless p.exist?
      raise Stickler::Error, "#{path} is not readable" unless p.readable?
      parse( p.read )
    end

    def depends_on?( name )
      gem_dependencies.any?{ |spec| spec.name == name }
    end

    private

    def parse( text )
      parts             = partition( text )
      @gem_dependencies = parse_dependencies( parts['GEM'] )
    end

    def parse_dependencies( lines )
      drop_until_specs( lines )
      deps = []
      lines.each do |line|
        md = line.match( /\A\s{4}(\S+)\s+\(([\w\.]+)\)\Z/ )
        next if md.nil?
        deps << Stickler::SpecLite.new( md.captures[0], md.captures[1] )
      end
      return deps
    end

    def drop_until_specs( lines )
      lines.drop_while{ |l| %w[ remote specs ].include?( l.strip.split(":").first ) }
    end

    def partition( text )
      text.split("\n\n").each_with_object({}) { | p, h |
        next if p.empty?
        parts = p.split("\n").map(&:rstrip)
        h[parts.first] = parts[1..-1]
      }
    end
  end
end
