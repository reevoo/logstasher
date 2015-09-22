require 'logger'
require 'logstasher/log_formatter'

module LogStasher
  class << self
    attr_reader :append_fields_callback
    attr_writer :enabled
    attr_writer :include_parameters
    attr_writer :serialize_parameters
    attr_writer :silence_standard_logging

    def append_fields(&block)
      @append_fields_callback = block
    end

    def enabled?
      if @enabled.nil?
        @enabled = false
      end

      @enabled
    end

    def include_parameters?
      if @include_parameters.nil?
        @include_parameters = true
      end

      @include_parameters
    end

    def serialize_parameters?
      if @serialize_parameters.nil?
        @serialize_parameters = true
      end

      @serialize_parameters
    end

    def initialize_logger(device = $stdout, level = ::Logger::INFO)
      ::Logger.new(device).tap do |new_logger|
        new_logger.level = level
      end
    end

    def logger
      @logger ||= initialize_logger
    end

    def logger=(log)
      @logger = log
    end

    def logger_for_app(app_tag, root_dir = nil, level = Logger::INFO)
      logger.formatter = LogFormatter.new(app_tag, root_dir)
      logger.level = level
      logger
    end

    def silence_standard_logging?
      if @silence_standard_logging.nil?
        @silence_standard_logging = false
      end

      @silence_standard_logging
    end
  end
end

require 'logstasher/railtie' if defined?(Rails)
