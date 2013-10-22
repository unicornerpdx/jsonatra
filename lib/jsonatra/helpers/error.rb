module Jsonatra
  module ErrorHelpers

    # sets a default root error type and message if not present, and appends this
    # error to the list for this parameter
    #
    def param_error parameter, type, message
      response.add_parameter_error parameter.to_sym, type, message
    end

    # converts model errors to response parameter errors, optionally mapping field
    # names to parameter names with the provided hash
    #
    def model_param_errors model, map = {}
      model.errors.each do |field, messages|
        messages.each do |message|
          type = :invalid
          mapped_parameter = map[field] || field

          # TODO find better way to case on this?
          if message == 'is not present'
            type = :required
            message = "#{mapped_parameter.camelcase} is required"
          end

          param_error mapped_parameter.camelcase, type, message
        end
      end
    end

    # sets a default root error type and message if not present, and appends this
    # error to the list for this header
    #
    def header_error header, type, message
      response.add_header_error header, type, message
    end
  end
end
