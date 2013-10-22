module Jsonatra
  module ErrorHelpers

    # sets a default root error type and message if not present, and appends this
    # error to the list for this parameter
    #
    def param_error parameter, type, message, &block
      response.add_parameter_error parameter.to_sym, type, message, &block
    end

    # sets a default root error type and message if not present, and appends this
    # error to the list for this header
    #
    def header_error header, type, message, &block
      response.add_header_error header, type, message, &block
    end
  end
end
