module LogStasher
  class LogFormatter
    attr_reader :base_tags
    attr_reader :root_dir
    attr_reader :release

    def initialize(base_tags = [], root_dir = nil)
      @base_tags = Array(base_tags)
      @root_dir = root_dir
      @release = $1 if root_dir && root_dir =~ /releases\/([^\/]+)/
    end

    def call(severity, datetime, progname, message)
      event = {
        '@timestamp' => datetime.utc,
        '@version' => '1',
        severity: severity.downcase,
      }.merge(format(message))

      event.merge!(format(progname)) if progname.is_a?(Exception)
      event[:tags] = base_tags + Array(event[:tags])
      event.to_json + "\n"
    end

    def format(data)
      return { message: data } if data.is_a?(String)
      return format_exception(data) if data.is_a?(Exception)
      return format_hash(data) if data.is_a?(Hash)
      fail ArgumentError, "Not expected type of log message: #{data} (#{data.class})"
    end

    private

    def format_hash(data)
      data.merge!(request_path: data[:path]) if data[:path] # logstash overrides the path attribute
      if data[:exception]
        format_exception(data.delete(:exception)).merge(data)
      else
        data
      end
    end

    def format_exception(exception)
      result = {
        tags: 'exception',
        error_class: exception.class.to_s,
        error_message: exception.message,
        error_source: error_source(exception),
        error_backtrace: exception.backtrace,
      }

      if exception.respond_to?(:cause) && exception.cause
        result[:error_cause] = [exception.cause.class.to_s, exception.cause.message].concat(exception.cause.backtrace)
      end
      result
    end

    def error_source(exception)
      source = exception.backtrace.find { |line| line.match(/\A#{root_dir}/) }
      source.sub(/\A#{root_dir}/, '') if source
    end
  end
end
