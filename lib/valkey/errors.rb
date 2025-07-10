# frozen_string_literal: true

class Valkey
  class BaseError < StandardError; end

  class ProtocolError < BaseError
    def initialize(reply_type)
      super(<<-MESSAGE.gsub(/(?:^|\n)\s*/, " "))
        Got '#{reply_type}' as initial reply byte.
        If you're in a forking environment, such as Unicorn, you need to
        connect to Valkey after forking.
      MESSAGE
    end
  end

  class CommandError < BaseError; end

  class PermissionError < CommandError; end

  class WrongTypeError < CommandError; end

  class OutOfMemoryError < CommandError; end

  class NoScriptError < CommandError; end

  class BaseConnectionError < BaseError; end

  class CannotConnectError < BaseConnectionError; end

  class ConnectionError < BaseConnectionError; end

  class TimeoutError < BaseConnectionError; end

  class InheritedError < BaseConnectionError; end

  class ReadOnlyError < BaseConnectionError; end

  class InvalidClientOptionError < BaseError; end

  class SubscriptionError < BaseError; end
end
