module Jsonatra
  class Base < Sinatra::Base

    class << self

      # because some parameters can be too large for normal GET query strings,
      # all GET routes also accept a POST with body data, with the same parameter
      # names and behavior
      #
      alias_method :sinatra_get, :get
      def get(*args, &block)
        sinatra_get *args, &block
        post *args, &block
      end
    end

  end
end
