
# Copyright (c) 2008 Jeremy Hinegardner
# All rights reserved.  Licensed under the same terms as Ruby.  No warranty is
# provided.  See LICENSE and COPYING for details.
#++

require 'stickler'
require 'fileutils'
require 'ostruct'
require 'highline'
require 'stickler/configuration'
require 'stickler/source_group'

module Stickler
  # 
  # A Repository a directory with a particular layout used by stickler.  It is
  # is very similar to a GEM_HOME directory.   The layout is as follows, this is
  # all assumed to be under STICKLER_HOME.
  #
  #   stickler.yml    - the Stickler configuration file for this repository.
  #                     The existence of this file indicates this is the root 
  #                     of a stickler repository
  #   gems/          - storage of the actual gem files, somewhat similar to the
  #                     GEM_HOME/cache directory
  #   specifications/ - ruby gemspec files 
  #   log/            - directory holding rotating logs files for stickler
  #   dist/           - directory holding the distributable gem index location,
  #                     rsync this to your webserver, or serve from it directly.
  #   log/            - directory holding the rolling logs of what has gone on
  #                     with the repository.
  #
  #   upsteram_source_cache/   - directory holding serialized Source objects for caching
  #
  #
  class Repository
    class Error < ::StandardError ; end

    # The repository directory.  the directory containing the stickler.yml file
    attr_reader :directory

    # The configuration
    attr_reader :configuration

    # Are requrements satisfied in a minimal or maximal approach
    attr_reader :requirement_satisfaction_method

    class << self
      def other_dir_names 
        %w[ gems_dir log_dir specification_dir dist_dir upstream_source_cache_dir ]
      end

      def config_file_basename
        "stickler.yml"
      end

      def basedir
        "stickler"
      end

      # 
      # What should the default stickler directory be, this is one of two
      # things.  If there is a stickler.yml file in the current directory, then
      # the default directory is the current directory, otherwise, it is the
      # _stickler_ directory below the current_directory
      #
      def default_directory
         
        defaults = [ File.join( Dir.pwd, config_file_basename ), File.join( Dir.pwd, basedir ) ]
        defaults.each do |def_dir|
          if File.exist?( def_dir ) then
            return File.dirname( def_dir ) if File.file?( def_dir )
            return def_dir
          end
        end
        return defaults.last
      end
    end

    def initialize( opts )

      @directory = File.expand_path( opts['directory'] )
      @requirement_satisfaction_method = ( opts['requirements'] || "maximum" ).to_sym
      enhance_logging( opts ) if File.directory?( log_dir )
      @overwrite = opts['force']

      # this must be loaded early so it overrites the global Gem.configuration
      @configuration_loaded = false
      load_configuration if File.exist?( config_file )

    end

    def configuration_loaded?
      @configuration_loaded
    end

    #
    # should existing items be overwritten
    #
    def overwrite?
      @overwrite
    end

    #
    # update logging by turning on a log file in the repository directory, and
    # possibly turning off the stdout logger that is the default.
    #
    def enhance_logging( opts )

      layout = ::Logging::Layouts::Pattern.new(
        :pattern      => "[%d] %c %6p %5l : %m\n",
        :date_pattern => "%Y-%m-%d %H:%M:%S"
      )
      Logging::Logger.root.add_appenders ::Logging::Appenders::RollingFile.new( 'stickler_rolling_logfile',
                                                                 { :filename => log_file,
                                                                   :layout   => layout,
                                                                   # at 5MB roll the log
                                                                   :size     => 5 * (1024**2),
                                                                   :keep     => 5,
                                                                   :safe     => true,
                                                                   :level    => :debug
                                                                  }) 
    end

    #
    # return a handle to the repository configuration found in stickler.yml.
    # Set this to be the global Gem.configuration
    #
    def load_configuration
      begin
        @configuration = Configuration.new( config_file )
        source_group # force a load
        @configuration_loaded = true
      rescue => e
        logger.error "Failure to load configuration #{e}"
        exit 1
      end
    end

    #
    # The configuration file for the repository
    # 
    def config_file
      @config_file ||= File.join( directory, Repository.config_file_basename )
    end

    #
    # The log directory
    #
    def log_dir
      @log_dir ||= File.join( directory, 'log' )
    end

    #
    # The log file 
    #
    def log_file
      @log_file ||= File.join( log_dir, 'stickler.log' )
    end

    #
    # The gem storage directory.  
    #
    # This holds the raw gem files downloaded from the sources.  This is
    # equivalent to a gem installations 'gems' directory.
    #
    def gems_dir
      @gems_dir ||= File.join( directory, 'gems' )
    end

    #
    # The Gem specification directory
    #
    def specification_dir
      @specification_dir ||= File.join( directory, 'specifications' )
    end

    #
    # The uppstream source cache directory
    #
    def upstream_source_cache_dir
      @source_cache_dir ||= File.join( directory, 'upstream_source_cache' )
    end

    #
    # The Distribution directory
    #
    # this is the document root for the webserver that will serve your rubygems.
    # Or they can be served directly from this location
    #
    def dist_dir
      @dist_dir ||= File.join( directory, 'dist' )
    end

    #
    # Local handler to the top level Stickler logger
    #
    def logger
      @logger ||= ::Logging::Logger[self]
    end


    # 
    # The SourceGroup containing all of the sources for this repository
    #
    def source_group
      unless @source_group
        sg = SourceGroup.new( self )
        Console.info "Setting up sources"
        configuration.sources.each do |source_uri|
          sg.add_source( source_uri )
        end
        @source_group = sg 
      end 
      return @source_group
    end

    #
    # Is the repository valid?
    #
    def valid?
      if @valid.nil? then 
        begin
          valid!
          @valid = true
        rescue StandardError => e
          logger.error "Repository is not valid : #{e}"
          @valid = false
        end
      end
      return @valid
    end

    #
    # raise an error if the repository is not valid
    #
    def valid!
      raise Error, "#{directory} does not exist" unless File.exist?( directory )
      raise Error, "#{directory} is not writable" unless File.writable?( directory )

      raise Error, "#{config_file} does not exist" unless File.exist?( config_file )
      raise Error, "#{config_file} is not loaded" unless configuration

      Repository.other_dir_names.each do |method|
        other_dir = self.send( method )
        raise Error, "#{other_dir} does not exist" unless File.exist?( other_dir )
        raise Error, "#{other_dir} is not writeable" unless File.writable?( other_dir )
      end

      if File.exist?( log_file ) then
        raise Error, "#{log_file} is not writable" unless File.writable?( log_file )
      end
    end

    #
    # Setup the repository. 
    #
    # This is executed with the 'setup' mode on the command line. Only those
    # files and directories that do not already exist are created.  Nothing is
    # destroyed.
    # 
    def setup 
      if File.exist?( directory ) then
        Console.info "repository root already exists #{directory}"
      else
        FileUtils.mkdir_p( directory ) 
        Console.info "created repository root #{directory}"
      end

      Repository.other_dir_names.each do |method|
        d = self.send( method )
        if File.exist?( d ) then
          Console.info "directory #{d} already exists"
        else
          FileUtils.mkdir_p( d ) 
          Console.info "created directory #{d}"
        end
      end

      if overwrite? or not File.exist?( config_file ) then
        FileUtils.cp Stickler::Paths.data_path( Repository.config_file_basename ), config_file
        Console.info "copied in default configuration to #{config_file}"
      else
        Console.info "configuration file #{config_file} already exists"
      end

      # load the configuration for the repo
      load_configuration

    rescue => e
      $stderr.puts "Unable to setup the respository"
      $stderr.puts e
      $stderr.puts e.backtrace.join("\n")
      exit 1
    end

    #
    # Report information about the repository.  This is what is called from the
    # 'info' mode on the commandline
    #
    def info
      return unless valid?

      Console.info ""
      Console.info "Upstream Sources"
      Console.info "----------------"
      Console.info ""

      max_width = configuration.sources.collect { |k| k.length }.max
      source_group.sources.each do |source|
        Console.info "  #{source.uri.rjust( max_width )} : #{source.latest_specs.size} gems available"
      end


      keys = configuration.keys
      max_width = keys.collect { |k| k.length }.max

      keys = keys.sort - %w[ sources ]

      Console.info ""
      Console.info "Configuration variables"
      Console.info "-----------------------"
      Console.info ""

      keys.each do |key|
        Console.info "  #{key.rjust( max_width )} : #{configuration[ key ]}"
      end
    end

    #
    # Add a source to the repository
    #
    def add_source( source_uri )
      load_configuration unless configuration_loaded?
      begin 
        uri = ::URI.parse source_uri
        if configuration.sources.include?( source_uri ) then
          Console.info "#{source_uri} already in sources"
        else
          configuration.sources << source_uri
          configuration.write
          source_group.add_source( source_uri )
          Console.info "#{source_uri} added to sources"
        end
      rescue ::URI::Error
        Console.info "Error : #{source_uri} is not a URI"
      end
    end

    #
    # Remove a source from the repository
    #
    def remove_source( source_uri )
      load_configuation unless configuration_loaded?
      begin
        uri = ::URI.parse source_uri
        if configuration.sources.delete( source_uri ) then
          source_group.remove_source( source_uri )
          configuration.write
          Console.info "#{source_uri} removed from sources"
          logger.warn "Still need to cleanup gems and source cache"
        else
          Console.info "#{source_uri} is not one of your sources"
          Console.info "Your sources are:"
          configuration.sources.each do |src|
            Console.info "  #{src}"
          end
        end
      rescue ::URI::Error
        Console.info "Error : #{source_uri} is not a URI"
      end
    end

    #
    # Add a gem to the repository
    #
    def add_gem( gem_name, version )

      Console.info ""

      version = ::Gem::Requirement.default if version == :latest
      search_pattern = ::Gem::Dependency.new( gem_name, version ) 
      choices = {}
      source_group.search( search_pattern ).each do |spec|
        choices[ spec.full_name ] = spec
      end

      ::HighLine.track_eof = false
      ::HighLine.new( STDIN, STDOUT).choose do |menu|
        menu.header = "Available versions of #{gem_name}"
        menu.prompt = "Choose the version to add ? "
        menu.shell = true
        menu.choices( *choices.keys.sort.reverse ) do |name, details|
          source_group.install( choices[ name ] )
        end

        menu.choice( :all ) do |all, details |
          choices.values.each { |spec| source_group.install( spec ) }
        end
      end
    end
  end
end
