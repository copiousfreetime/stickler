require 'sinatra/base'
require 'rubygems/source_index'

module Stickler
  class GemServer < ::Sinatra::Base

    # An array of fully expanded directories indicating locations of gems
    # It should hold something similar to Gem.path
    attr_reader :gem_path

    # Gem::SourceIndex used for this server
    attr_reader :source_index

    def initialize( app = nil, opts = {} )
      @gem_path     = [ opts[:gem_path] ].flatten
      @source_index = Gem::SourceIndex.from_gems_in( *spec_dirs )
      puts "Using GEM_PATH #{gem_path.join(':')}"
      super( app )
    end

    def spec_dirs
      @spec_dirs ||= gem_path.collect{ |dir| File.join( dir, "specifications" ) }
    end

    def sorted_lightweight_specs_of( specs )
      specs.sort.collect do |spec|
        platform = spec.original_platform
        platform = Gem::Platform::RUBY if platform.nil?
        [ spec.name, spec.version, platform ]
      end
    end

    before do
      source_index.refresh!
      response["Date"] = spec_dirs.collect do |dir|
        File.stat(dir).mtime
      end.sort.last.to_s
    end


    # some fancy schmacny webpage
    get '/' do
      s = []
      source_index.latest_specs.sort_by { |spec| spec.full_name }.each do |spec|
        s << "#{spec.name}\t#{spec.version}"
      end
      content_type "text/plain"
      s.join("\n")
    end

    get %r{\A/yaml(\.Z)?\Z} do |deflate|
      content_type "text/plain"
      env['stickler.compress'] = 'deflate' if deflate
      source_index.to_yaml
    end

    get %r{\A/Marshal.#{Gem.marshal_version}(\.Z)?\Z} do |deflate|
      env['stickler.compress'] = 'deflate' if deflate
      marshal( source_index )
    end

    get %r{\A/specs.#{Gem.marshal_version}(\.gz)?\Z} do |gzip|
      env['stickler.compress'] = 'gzip' if gzip
      marshalled_specs( source_index.gems.values )
    end

    get %r{\A/latest_specs.#{Gem.marshal_version}(.gz)?\Z} do |gzip|
      env['stickler.compress'] = 'gzip' if gzip
      marshalled_specs( source_index.latest_specs )
    end

    get "/quick/" do
    end

    # /gems
    # /cache
    #
    def marshalled_specs( spec_list )
      marshal( sorted_lightweight_specs_of( spec_list ) )
    end

    def marshal( data )
      content_type 'application/octet-stream'
      ::Marshal.dump( data )
    end
  end
end
