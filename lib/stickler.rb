#--
# Copyright (c) 2008 Jeremy Hinegardner
# All rights reserved.  Licensed under the same terms as Ruby.  No warranty is
# provided.  See LICENSE and COPYING for details.
#++

require 'logging'

module Stickler

  #
  # Setup top level logging to stdout.  Good idea taken from Webby.
  #
  def self.logger
    unless @logger 
      @logger = ::Logging::Logger['Stickler']
      @logger.level = :debug
      @logger.add_appenders(::Logging::Appender.stdout)
      ::Logging::Appender.stdout.layout = Logging::Layouts::Pattern.new(
        :pattern        => "[%d] %5l : %m\n",   # [date] LEVEL: message 
        :date_pattern    => "%H:%M:%S"          # [date] => [HH:MM::SS]
      )
      ::Logging::Appender.stdout.level = :info
    end
    return @logger
  end
  Stickler.logger # force it to be initialized

  #
  # Turn off the stdout logging
  #
  def self.silent!
    ::Logging::Appender.stdout.level = :off
  end

  #
  # Turn off logging for the execution of a block
  #
  def self.silent( &block )
    begin
      old_level = @logger.level
      @logger.level = :off
      block.call
    ensure
      @logger.level = old_level
    end
  end

  #
  # Up the logging to debug levels
  #
  def self.debug!
    @logger.level = :debug
  end

  #
  # Send to both STDOUT and the loggers, but turn off the stdout logger before
  # and turn it back on afterwards.
  #
  # This is useful for logging information in a pleasing manner to stdout and
  # also to have it sent to non-stdout logs
  #
  def self.tee( msg )
    prev_level = ::Logging::Appender.stdout.level
    ::Logging::Appender.stdout.level = :off
    @logger.info msg
    ::Logging::Appender.stdout.level = prev_level

    $stdout.puts msg
  end
end

require 'stickler/paths'
require 'stickler/version'
require 'stickler/repository'
require 'stickler/installer'
require 'stickler/configuration'
require 'stickler/cli'
