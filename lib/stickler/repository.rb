
# Copyright (c) 2008 Jeremy Hinegardner
# All rights reserved.  Licensed under the same terms as Ruby.  No warranty is
# provided.  See LICENSE and COPYING for details.
#++

require 'stickler'
require 'fileutils'
require 'ostruct'

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

    #
    # The repository has customizations created via an eval'd file.  That file
    # is +config_file+ and it is done via a yeilded OpenStruct
    #
    class << self
      def configuration
        cfg = OpenStruct.new
        yield cfg
        return cfg
      end
    end

    # The repository directory.  the directory containing the stickler.yml file
    attr_reader :directory

    def initialize( opts )
      @directory = File.expand_path( opts['directory'] )
      enhance_logging( opts ) unless opts['skip_validity_check'] or not valid?
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
    # return a handle to the repository configuration found in stickler.yml
    #
    def configuration
      unless @configuration 
        @config_contents = File.read(config_file)
        begin
          @configuration = eval( @config_contents )
          @configuration.upstream = [ @configuration.upstream ].flatten
        rescue => e
          logger.error "Failure to load configuration #{e}"
          exit 1
        end
      end
      return @configuration
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
    # The rdoc directory
    #
    def rdoc_dir
      @rdoc_dir ||= File.join( directory, 'doc' )
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
      raise "#{directory} does not exist" unless File.exist?( directory )
      raise "#{directory} is not writable" unless File.writable?( directory )

      raise "#{config_file} does not exist" unless File.exist?( config_file )
      raise "#{config_file} is not loaded" unless configuration

      %w[ gem_dir log_dir rdoc_dir specification_dir ].each do |method|
        sub_dir= self.send( method )
        raise "#{sub_dir} does not exist" unless File.exist?( sub_dir )
        raise "#{sub_dir} is not writeable" unless File.writable?( sub_dir )
      end

      if File.exist?( log_file ) then
        raise "#{log_file} is not writable" unless File.writable?( log_file )
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
      unless File.exist?( directory )
        FileUtils.mkdir_p( directory ) 
        logger.info "created repository root #{directory}"
      end

      %w[ gem_dir log_dir rdoc_dir specification_dir ].each do |sub_dir|
        d = self.send(sub_dir)
        unless File.exist?( d )
          FileUtils.mkdir_p( d ) 
          logger.info "created directory #{d}"
        end
      end

      unless File.exist?( config_file )
        FileUtils.cp Stickler::Configuration.data_path( "stickler.yml"), config_file
        logger.info "copied in default configuration to #{config_file}"
      end

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
      Stickler.tee "Configuration settings:"
      cfg_params = %w[ upstream gem_server_home ]
      max_width = cfg_params.collect { |cp| cp.length }.max
      cfg_params.sort.each do |param|
        Stickler.tee "    #{param.rjust(max_width)} : #{configuration.send(param)}"
      end
    end
  end
end
