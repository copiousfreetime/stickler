require 'sinatra/base'
require 'rubygems/source_index'

module Stickler
  class GemServer < ::Sinatra::Base

    # Gem::SourceIndex used for this server
    attr_reader :source_index

    def initialize( app = nil, opts = {} )
      @default_gem_path     = [ opts[:gem_path] ].flatten
      @source_index = Gem::SourceIndex.new
      super( app )
    end

    def spec_dirs
      gem_path.collect{ |dir| File.join( dir, "specifications" ) }
    end

    def gem_path
      if env.has_key?( 'stickler.gem_path' ) then
        puts "env['stickler.gem_path'] => #{env['stickler.gem_path']}"
      end
      env['stickler.gem_path'] || []
    end

    before do
      if spec_dirs.size > 0 then
        puts "Spec dirs => #{spec_dirs.inspect}"
        source_index.load_gems_in( *spec_dirs )
        response["Date"] = spec_dirs.collect do |dir|
          File.stat(dir).mtime
        end.sort.last.to_s
      else
        puts "No spec dirs yet"
      end
    end


    # some fancy schmacny webpage
    get '/' do
      s = []
      if source_index.latest_specs.size > 0 then 
        source_index.latest_specs.sort_by { |spec| spec.full_name }.each do |spec|
          s << "#{spec.name}\t#{spec.version}"
        end
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

    get %r{\A/gems/:gemfile\Z} do
      puts "Finding gem #{params[:gemfile]} ?"
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

      spec = find_spec_for( name, version, platform )
     
      env['stickler.compress'] = 'deflate' if deflate

      if marshal then
        marshal( spec )
      else
        spec.to_yaml
      end
    end

    #
    # Actually serve up the gem
    #
    get %r{\A/gems/(.*?)-([0-9.]+)(-.*?)?\.gem\Z} do
      name, version, platform = *params[:captures]
      spec = find_spec_for( name, version, platform )
      full_path = File.join( spec.installation_path, 'gems', spec.file_name )
      content_type 'application/x-tar'
      IO.read( full_path )
    end

    def find_spec_for( name, version, platform )
      platform  = platform ? Gem::Platform.new( platform.sub(/\A-/,'')) : Gem::Platform::RUBY
      dep       = Gem::Dependency.new( name, version )
      specs     = source_index.search( dep )
      specs     = specs.find_all { |spec| spec.platform == platform }
      full_name = "#{name}-#{version}"
      full_name += "-#{platform}" unless platform == Gem::Platform::RUBY

      content_type 'text/plain'
      not_found "No gems found matching [#{full_name}]"           if specs.empty?
      error( 500, "Multiple gems found matching [#{full_name}]" ) if specs.size > 1

      return specs.first
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
