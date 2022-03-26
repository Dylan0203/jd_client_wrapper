# frozen_string_literal: true

module JdClientWrapper
  class JdClientWrapperError < StandardError; end
  class MissingOption < JdClientWrapperError; end
  class InvalidMode < JdClientWrapperError; end
  class RequestError < JdClientWrapperError; end
end
