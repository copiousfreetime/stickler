#--
# Copyright (c) 2008 Jeremy Hinegardner
# All rights reserved.  Licensed under the same terms as Ruby.  No warranty is
# provided.  See LICENSE and COPYING for details.
#++

require 'logging'

module Stickler

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
