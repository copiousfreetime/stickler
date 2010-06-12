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
      marshalled_specs( gems.values )
    end

    get %r{\A/latest_specs.#{Gem.marshal_version}(\.gz)?\Z} do |gzip|
      env['stickler.compress'] = 'gzip' if gzip
      marshalled_specs( latest_specs )
    end

    get %r{\A/quick/index(\.rz)?\Z} do |deflate|
      env['stickler.compress'] = 'deflate' if deflate
      sorted_text( gems.keys )
    end

    get %r{\A/quick/latest_index(\.rz)?\Z} do |deflate|
      env['stickler.compress'] = 'deflate' if deflate
      sorted_text( latest_specs.collect { |spec| spec.full_name } )
    end

    #
    # Match a single gem spec request, returning in Marshal format or the deprecated
    # yaml format.  This Regex is from 'Gem::Server' with a slight alteration
    # to allow for optional deflating of the output.
    #
    # optional deflating of the output should only be used for debugging
    #
    get %r{\A/quick(/Marshal\.#{Regexp.escape(Gem.marshal_version)})?/((.*?)-([0-9.]+)(-.*?)?)\.gemspec(\.rz)?\Z} do 
      marshal, full_name, name, version, platform, deflate = *params[:captures]

      platform = platform ? Gem::Platform.new( platform.sub(/\A-/,'')) : Gem::Platform::RUBY
      dep      = Gem::Dependency.new( name, version )
      specs    = source_index.search( dep )
      specs    = specs.find_all { |spec| spec.platform == platform }

      content_type 'text/plain'
      not_found "No gems found matching [#{full_name}]"           if specs.empty?
      error( 500, "Multiple gems found matching [#{full_name}]" ) if specs.size > 1
      
      env['stickler.compress'] = 'deflate' if deflate

      if marshal then
        marshal( specs.first )
      else
        specs.first.to_yaml
      end
    end

    def marshalled_specs( spec_list )
      marshal( sorted_lightweight_specs_of( spec_list ) )
    end

    def marshal( data )
      content_type 'application/octet-stream'
      ::Marshal.dump( data )
    end

    def gems
      source_index.gems
    end

    def latest_specs
      source_index.latest_specs
    end

    def sorted_lightweight_specs_of( specs )
      specs.sort.collect do |spec|
        platform = spec.original_platform
        platform = Gem::Platform::RUBY if platform.nil?
        [ spec.name, spec.version, platform ]
      end
    end

    def sorted_text( list )
      content_type "text/plain"
      list.sort.join("\n")
    end
  end
end
