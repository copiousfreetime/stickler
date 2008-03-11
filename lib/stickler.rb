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
      @logger.level = :info
      @logger.add_appenders(::Logging::Appender.stdout)
      ::Logging::Appender.stdout.layout = Logging::Layouts::Pattern.new(
        :pattern        => "[%d] %5l : %m\n",   # [date] LEVEL: message 
        :date_pattern    => "%H:%M:%S"          # [date] => [HH:MM::SS]
      )
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
  # also to have it sent non-stdout logs
  #
  def self.tee( msg )
    prev_level = ::Logging::Appender.stdout.level
    ::Logging::Appender.stdout.level = :off
    @logger.info msg
    ::Logging::Appender.stdout.level = prev_level

    $stdout.puts msg
  end

  #
  # recursively descend the directory with the same name as this file and do a
  # require 'stickler/path/to/file'
  #
  def self.require_all_libs_relative_to_me
    remove_parent = File.dirname(File.expand_path(__FILE__)) + File::SEPARATOR
    descend_dir   = File.join(remove_parent,File.basename(__FILE__, ".rb"))

    Dir.glob("#{descend_dir}/**/*.rb").each do |rb|
      lib = rb.gsub(remove_parent,'')
      require lib
    end
  end
end

Stickler.require_all_libs_relative_to_me
