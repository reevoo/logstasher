module LogStasher
  class LogFormatter < Logger::Formatter
    attr_reader :app_tag
    attr_reader :root_dir

    def initialize(app_tag, root_dir = nil)
      @app_tag = app_tag
      @root_dir = root_dir
    end

    def call(severity, datetime, _, data)
      {
        '@timestamp' => datetime.utc,
        '@version' => '1',
        severity: severity.downcase,
        tags: [app_tag],
      }.merge(format(data)).to_json + "\n"
    end

    def format(data)
      if data.is_a?(String)
        { message: data }
      elsif data.is_a?(Exception)
        format_exception(data)
      elsif data.is_a?(Hash) && data[:path]
        data.merge(request_path: data[:path])
      else
        data
      end
    end

    private

    def format_exception(exception) # rubocop:disable Metrics/AbcSize
      result = {
        tags: [app_tag, 'exception'],
        error_class: exception.class.to_s,
        error_message: exception.message,
        error_backtrace: exception.backtrace,
      }
      result[:error_source] = exception.backtrace.find { |line| line.match(/\A#{root_dir}/) } if root_dir

      if exception.respond_to?(:cause) && exception.cause
        result[:error_cause] = [exception.cause.class.to_s, exception.cause.message].concat(exception.cause.backtrace)
      end
      result
    end
  end
end
