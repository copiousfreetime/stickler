
# Copyright (c) 2008 Jeremy Hinegardner
# All rights reserved.  Licensed under the same terms as Ruby.  No warranty is
# provided.  See LICENSE and COPYING for details.
#++

require 'stickler'
require 'fileutils'
require 'stickler/configuration'

module Stickler
  # 
  # A Repository a directory with a particular layout used by stickler.  It is
  # is very similar to a GEM_HOME directory.   The layout is as follows, this is
  # all assumed to be under STICKLER_HOME.
  #
  #   stickler.yml    - the Stickler configuration file for this repository.
  #                     The existence of this file indicates this is the root 
  #                     of a stickler repository
  #   gems/           - storage of the actual gem files, somewhat similar to the
  #                     GEM_HOME/cache directory
  #   specifications/ - ruby gemspec files 
  #   log/            - directory holding rotating logs files for stickler
  #   dist/           - directory holding the distributable gem index location,
  #                     rsync this to your webserver, or serve from it directly.
  #   log/            - directory holding the rolling logs of what has gone on
  #                     with the repository.
  #
  #
  class Repository
    class Error < ::StandardError ; end

    # The repository directory.  the directory containing the stickler.yml file
    attr_reader :directory

    # The configuration
    attr_reader :configuration

    def self.other_dir_names 
      %w[ gem_dir log_dir specification_dir dist_dir ]
    end

    def initialize( opts )
      @directory = File.expand_path( opts['directory'] )
      enhance_logging( opts ) if File.directory?( log_dir )
      @overwrite = opts['force']

      # this must be loaded early so it overrites the global Gem.configuration
      load_configuration if File.exist?( config_file )

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
      Stickler.silent! if opts['quiet']

      layout = ::Logging::Layouts::Pattern.new(
        :pattern      => "[%d] %c %6p %5l : %m\n",
        :date_pattern => "%Y-%m-%d %H:%M:%S"
      )
      logger.add_appenders ::Logging::Appenders::RollingFile.new( 'stickler_rolling_logfile',
                                                                 { :filename => log_file,
                                                                   :layout   => layout,
                                                                   # at 5MB roll the log
                                                                   :size     => 5 * (1024**2),
                                                                   :keep     => 5,
                                                                   :safe     => true,
                                                                   :level    => :debug
                                                                  }) 
      Stickler.debug! if opts['debug']
    end

    #
    # return a handle to the repository configuration found in stickler.yml.
    # Set this to be the global Gem.configuration
    #
    def load_configuration
      begin
        @configuration = Configuration.new( config_file )
        ::Gem.configuration = @configuration 
      rescue => e
        logger.error "Failure to load configuration #{e}"
        exit 1
      end
    end

    #
    # The configuration file for the repository
    # 
    def config_file
      @config_file ||= File.join( directory, 'stickler.yml' )
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
    # This holds the raw gem files downloaded from the sources
    #
    def gem_dir
      @gem_dir ||= File.join( directory, 'gems' )
    end

    #
    # The Gem specification directory
    #
    def specification_dir
      @specification_dir ||= File.join( directory, 'specifications' )
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
      @logger ||= Stickler.logger
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
      if overwrite? or not File.exist?( directory )
        FileUtils.mkdir_p( directory ) 
        logger.info "created repository root #{directory}"
      else
        logger.info "repository root already exiss #{directory}"
      end

      Repository.other_dir_names.each do |method|
        d = self.send( method )
        if overwrite? or not File.exist?( d ) 
          FileUtils.mkdir_p( d ) 
          logger.info "created directory #{d}"
        else
          logger.info "directory #{d} already exists"
        end
      end

      if overwrite? or not File.exist?( config_file ) then
        FileUtils.cp Stickler::Paths.data_path( "stickler.yml" ), config_file
        logger.info "copied in default configuration to #{config_file}"
      else
        logger.info "configuration file #{config_file} already exists"
      end

      # load the configuration for the repo
      load_configuration

    rescue => e
      logger.error "Unable to setup the respository"
      logger.error e
      exit 1
    end

    #
    # Report information about the repository.  This is what is called from the
    # 'info' mode on the commandline
    #
    def info
      return unless valid?
      Stickler.tee "Configuration settings"
      Stickler.tee "----------------------"
      Stickler.tee ""
      keys = configuration.keys
      max_width = keys.collect { |k| k.length }.max

      Stickler.tee "  #{"downstream_source".rjust( max_width )} : #{configuration['downstream_source']}"
      Stickler.tee "  #{"sources".rjust( max_width )} : #{configuration.sources.first}"

      configuration.sources[1..-1].each do |source|
        Stickler.tee "  #{"".rjust( max_width )}   #{source}"
      end

      Stickler.tee ""

      keys = keys.sort - %w[ downstream_source sources ]
      keys.each do |key|
        Stickler.tee "  #{key.rjust( max_width )} : #{configuration[ key ]}"
      end
    end

    def sources
      unless @sources 
        s = {}
        configuration.sources.each do |upstream_uri|
          src = Source.new( upstream_uri )
          @sources << Sources.new( upstream_uri )
        end
      end
      return @sources
    end

    #
    # Add a source to the repository
    #
    def add_source( source_uri )
      sources << Source.new( source_uri )
    end
  end
end
