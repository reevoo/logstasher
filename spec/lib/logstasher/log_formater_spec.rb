require 'spec_helper'
require 'logstasher/log_formatter'

describe LogStasher::LogFormatter do

  class TestError < StandardError
    def cause
      StandardError.new('Cause error message').tap do |err|
        err.set_backtrace(['/cause/item1.rb', '/cause/item2.rb'])
      end
    end
  end

  let(:exception_message) { 'Exception message' }
  let(:exception) do
    e = TestError.new(exception_message)
    e.set_backtrace(backtrace)
    e
  end
  let(:backtrace) do
    [
      '/foo/bar.rb',
      '/my/root/releases/12345/foo/broken.rb',
      '/bar/foo.rb',
    ]
  end

  subject { described_class.new('base-tag', '/my/root/releases/12345') }

  describe '#release' do
    it 'returns indetifier of release from the root dir' do
      expect(subject.release).to eq('12345')
    end
  end

  describe '#format' do
    context 'with string as an argument' do
      it 'returns hash with message key' do
        expect(subject.format('foo')).to eq({ message: 'foo' })
      end
    end

    context 'with exception as an argument' do

      it 'returns hash describing the exception' do
        expect(subject.format(exception)).to match({
          tags:            'exception',
          error_class:     'TestError',
          error_message:   exception_message,
          error_source:    '/foo/broken.rb',
          error_backtrace: backtrace,
          error_cause: [
            'StandardError',
            'Cause error message',
            '/cause/item1.rb',
            '/cause/item2.rb',
          ]
        })
      end
    end

    context 'with hash as an argument' do
      it 'returns hash as it is with path attribute copied to request_path' do
        # logstash overrides the path attribute
        expect(subject.format({ foo: 'bar', path: '/my/path' })).to match({
          foo:          'bar',
          path:         '/my/path',
          request_path: '/my/path',
        })
      end
    end

    context 'with hash containing exception key as an argument' do
      it 'returns hash describing the exception merged with items from origina hash' do
        expect(subject.format({ exception: exception, tags: 'custom_tag', foo: 'bar' })).to match({
          tags:            'custom_tag',
          error_class:     'TestError',
          error_message:   exception_message,
          error_source:    '/foo/broken.rb',
          error_backtrace: backtrace,
          error_cause:     [
            'StandardError',
            'Cause error message',
            '/cause/item1.rb',
            '/cause/item2.rb',
          ],
          foo:             'bar',
        })
      end
    end
  end

  describe '#call' do
    context 'when progname is nil' do
      let(:progname) { nil }

      it 'returns hash with message key' do
        result = JSON.parse(subject.call(
          :error,
          Time.new(2016, 01, 02, 03, 04, 05),
          progname,
          exception_message)).deep_symbolize_keys!

        expect(result).to include({
          message:  exception_message,
          severity: "error",
          tags:     ["base-tag"],
        })

        expect(result.keys).not_to include(:error_class, :error_message, :error_backtrace, :error_cause)
      end
    end

    context 'with progname is an exception' do
      let(:progname) { exception }

      it 'returns hash describing the exception' do
        result = JSON.parse(subject.call(
          :error,
          Time.new(2016, 01, 02, 03, 04, 05),
          progname,
          exception_message)).deep_symbolize_keys!

        expect(result).to include({
          message:         exception_message,
          tags:            'exception',
          error_class:     'TestError',
          error_message:   exception_message,
          error_source:    '/foo/broken.rb',
          error_backtrace: backtrace,
          error_cause:     [
            'StandardError',
            'Cause error message',
            '/cause/item1.rb',
            '/cause/item2.rb',
          ],
          severity:        "error",
          tags:            ["base-tag", "exception"],

        })
      end
    end
  end
end
