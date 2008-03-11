#--
# Copyright (c) 2008 Jeremy Hinegardner
# All rights reserved.  Licensed under the same terms as Ruby.  No warranty is
# provided.  See LICENSE and COPYING for details.
#++

require 'stickler'
require 'fileutils'
require 'configuration'

module Stickler
  # 
  # A Repository a directory with a particular layout used by stickler.  It is
  # is very similar to a GEM_HOME directory.   The layout is as follows, this is
  # all assumed to be under STICKLER_HOME.
  #
  #   stickler.rb     - sticker, the Stickler configuration file for this repository
  #   doc/            - Generated RDOC of all the gems
  #   gems/           - storage of the actual gem files, somewhat similar to GEM_HOME/cache
  #   specifications/ - ruby gemspec files 
  #   log/            - directory holding rotating logs files for stickler
  #   
  # 
  # Additionally, if a repository is instantiated and it is connected to an
  # already existing repo directory, a logfile appender is added for a logfile
  # in the log directory
  #
  class Repository

    # The repository directory
    attr_reader :directory

    def initialize(directory)
      @directory = File.expand_path(directory)
      @config_loaded = false
      load_config
      if valid? then
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
                                                                     :safe     => true
                                                                    }) 
      end
    end

    #
    # return a handle to the repository configuration found in stickler.rb
    #
    def configuration
      @configuration ||= ::Configuration.for('stickler')
    end

    #
    # The configuration file for the repository
    # 
    def config_file
      @config_file ||= File.join(directory, 'stickler.rb')
    end

    #
    # The log directory
    #
    def log_dir
      @log_dir ||= File.join(directory, 'log')
    end

    #
    # The log file 
    #
    def log_file
      @log_file ||= File.join(log_dir, 'stickler.log')
    end

    #
    # The rdoc directory
    #
    def rdoc_dir
      @rdoc_dir ||= File.join(directory, 'doc')
    end

    #
    # The gem storage directory
    #
    def gem_dir
      @gem_dir ||= File.join(directory, 'gems')
    end

    #
    # The Gem specification directory
    #
    def specification_dir
      @specification_dir ||= File.join(directory, 'specifications')
    end

    #
    # Local handler to the top level Stickler logger
    #
    def logger
      @logger ||= Stickler.logger
    end

    #
    # Load the configuration file if it exists.  If it is already loaded then do
    # nothing.  If there is an error loading the configuration that is logged.
    #
    def load_config
      require config_file if File.exist?(config_file)
      @config_loaded = true
    rescue LoadError => le
      logger.error "Error loading configuration file #{config_file}"
      logger.error le
    end

    #
    # Is the configuration loaded?
    #
    def config_loaded?
      @config_loaded
    end

    #
    # Is the repository valid?
    #
    def valid?
      valid!
      true
    rescue StandardError => e
      logger.error "Repository is not valid : #{e}"
      false
    end

    #
    # raise an error if the repository is not valid
    #
    def valid!
      raise "#{directory} does not exist" unless File.exist?( directory )
      raise "#{directory} is not writable" unless File.writable?( directory )

      raise "#{config_file} does not exist" unless File.exist?( config_file )
      raise "#{config_file} is not loaded" unless config_loaded?

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
        FileUtils.cp Stickler::Configuration.data_path("stickler.rb"), config_file
        logger.info "copied in default configuration to #{config_file}"
      end
      load_config
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
      methods = configuration.methods - Object.methods - ['method_missing']
      max_length = methods.collect { |m| m.to_s.size }.max

      Stickler.tee "Configuration settings:"
      methods.sort.each do |method|
        Stickler.tee "    #{method.rjust(max_length)} => #{configuration.send(method)}"
      end
    end
  end
end
