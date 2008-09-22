
module Stickler
  #
  # containment for the output that a user should see.  This uses a Logger so
  # that it can be throttled based on level at some point
  #
  class Console
    class << self
      #
      # Items that get logged to stdout for the user to see should use this logger
      #
      def logger
        unless @logger 
          @logger = ::Logging::Logger['User']
          @logger.level = :info
          @logger.add_appenders(::Logging::Appender.stdout)
          ::Logging::Appender.stdout.layout = Logging::Layouts::Pattern.new( :pattern => "%m\n" )
          ::Logging::Appender.stdout.level = :info
        end
        return @logger
      end

      # force initialization 
      Console.logger

      #
      # default logging leve
      #
      def default_level
        :info
      end

      #
      # Quick wrappers around the log levels
      #
      ::Logging::LEVELS.keys.each do |l|
        module_eval <<-code
          def #{ l }( msg )
            @logger.#{l} msg
          end
        code
      end

      #
      # Turn off the logging
      #
      def silent!
        logger.level = :off
      end

      #
      # Resume logging
      #
      def resume!
        logger.level = self.default_level
      end


      #
      # Turn off logging for the execution of a block
      #
      def silent( &block )
        begin
          silent!
          block.call
        ensure
          resume!
        end
      end
    end
  end
end
