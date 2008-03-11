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
  class Repository

    # The repository directory
    attr_reader :directory

    def initialize(directory)
      @directory = File.expand_path(directory)
      load_config
    end

    # The configuration file for the repository
    # 
    def config_file
      @config_file ||= File.join(directory, 'stickler.rb')
    end

    # The log file 
    #
    def log_file
      @log_file ||= File.join(directory, 'log', 'stickler.log')
    end

    # The rdoc directory
    #
    def rdoc_dir
      @rdoc_dir ||= File.join(directory, 'doc')
    end

    # The gem storage directory
    #
    def gem_dir
      @gem_dir ||= File.join(directory, 'gems')
    end

    # The Gem specification directory
    #
    def specification_dir
      @specification_dir ||= File.join(directory, 'specifications')
    end

    # Local handler to the top level Stickler logger
    #
    def logger
      @logger ||= Stickler.logger
    end

    # Load the configuration file if it exists.  If it is already loaded then do
    # nothing.  If there is an error loading the configuration that is logged.
    #
    def load_config
        require config_file if File.exist?(config_file)
    rescue LoadError => le
      logger.error "Error loading configuration file #{config_file}"
      logger.error le
    end

    # Setup the repository
    # 
    def setup
      unless File.exist?( directory )
        FileUtils.mkdir_p( directory ) 
        logger.info "created repository root #{directory}"
      end

      %w[ doc specifications gems log ].each do |sub_dir|
        s = File.join(directory, sub_dir)
        unless File.exist?( s )
          FileUtils.mkdir_p( s ) unless File.exist?( s )
          logger.info "created sub directory #{s}"
        end
      end

      cfg_file = File.join(directory, 'stickler.rb')
      unless File.exist?( cfg_file )
        FileUtils.cp Stickler::Configuration.data_path("stickler.rb"), cfg_file unless File.exist?(cfg_file)
        logger.info "copied in default configuration to #{File.join(directory, 'stickler.rb')}"
      end
    rescue => e
        logger.error "Unable to setup the respository"
        logger.error e
        exit 1
    end
  end
end
