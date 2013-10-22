module Jsonatra
  class Response < Sinatra::Response

    # do a `response.override_processing = true` in your route if you need to
    #
    @override_processing = false
    attr_accessor :override_processing

    # set this and the `content_type` in the `before` filter
    #
    attr_writer :jsonp_callback

    # new #finish method to handle error reporting and json(p)-ification
    #
    alias sinatra_finish finish
    def finish
      unless @override_processing
        if self.error?
          self.body = {error: @error.delete_if {|k,v| v.nil?}}.to_json
        else

          # TODO what if there are more elements in the array?
          #
          if Array === self.body
            self.body = self.body[0]

            # JSON is not valid unless it's "{}" or "[]"
            #
            self.body ||= {}
          end

          if Hash === self.body
            json_body = self.body.to_json
            if @jsonp_callback
              self.body = "#{@jsonp_callback}(#{json_body});"
            else
              self.body = json_body
            end
          end
        end
      end
      sinatra_finish
    end

    # new methods for adding and appending errors
    #

    def error
      @error ||= {}
      @error
    end

    def error?; !error.empty?; end

    def error_type= type
      error[:type] = type
    end

    def error_message= message
      error[:message] = message
    end

    def error_doc_url= doc_url
      error[:doc_url] = doc_url
    end

    def error= error_hash = {}
      self.error_type = error_hash[:type]
      self.error_message = error_hash[:message]
      self.error_doc_url = error_hash[:doc_url]
    end

    def add_parameter_error parameter, type, message
      error[:type] ||= 'invalidInput'
      error[:message] ||= 'invalid parameter or parameter value'
      error[:parameters] ||= {}
      error[:parameters][parameter.to_sym] ||= []
      error[:parameters][parameter.to_sym] << {type: type, message: message}
    end

    def add_header_error header, type, message
      error[:type] ||= 'invalidHeader'
      error[:message] ||= 'invalid header or header value'
      error[:headers] ||= {}
      error[:headers][header.to_sym] ||= []
      error[:headers][header.to_sym] << {type: type, message: message}
    end

  end
end
