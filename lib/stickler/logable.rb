require 'logging'
module Stickler

  def self.app_name
    @app_name || "stickler"
  end

  def self.app_name=( name )
    @app_name = name
  end

  class Logging
    def self.init
      unless @initialized then
        layout   = ::Logging::Layouts::Pattern.new( :pattern => "%5l %c : %m" )
        appender = ::Logging::Appenders::Syslog.new( Stickler.app_name,
                                                    :logopt => ::Syslog::Constants::LOG_CONS | ::Syslog::Constants::LOG_PID,
                                                    :facility => ::Syslog::Constants::LOG_LOCAL0,
                                                    :layout => layout)
        ::Logging::Appenders['syslog'] = appender
        logger = ::Logging::Logger[Stickler]
        logger.add_appenders( appender )
        @initialized = true
      end
      return @initialized
    end
  end

  module Logable
    def logger
      Stickler::Logging.init
      ::Logging::Logger[self]
    end
  end
end
