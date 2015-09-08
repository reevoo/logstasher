module LogStasher
  class LogFormatter
    def initialize(tags = [])
      @tags = Array(tags)
    end

    def call(severity, datetime, _, data)
      { '@timestamp' => datetime.utc, severity: severity.downcase, tags: tags }.merge(format(data)).to_json
    end

    def format(data)
      if data.is_a?(String)
        { message: data }
      elsif data.is_a?(Exception)
        format_exception(data)
      elsif data.is_a?(Hash) && data[:path]
        data.merge(request_path: data[:path])
      else
        { data: data }
      end
    end

    private

    def format_exception(exception) # rubocop:disable Metrics/AbcSize
      result = {
        error_class: exception.class.to_s,
        error_message: exception.message,
        error_source: exception.backtrace.find { |line| line.match(/\A#{Rails.root}/) },
        error_backtrace: exception.backtrace,
      }
      if exception.respond_to?(:cause) && exception.cause
        result[:error_cause] = [exception.cause.class.to_s, exception.cause.message].concat(exception.cause.backtrace)
      end
      result
    end
  end
end
