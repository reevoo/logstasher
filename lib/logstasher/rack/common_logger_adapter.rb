module LogStasher
  module Rack
    class CommonLoggerAdapter

      def initialize(logger)
        @logger = logger
      end

      def write(msg)
        @logger.info(tags: 'rack', message: msg)
      end
      
    end
  end
end
