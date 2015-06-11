module Jsonatra
  module ParamsHelpers

    JSON_CONTENT_TYPE = 'application/json'.freeze

    # merges JSON POST body data over query params if provided
    #
    def params
      unless @_params_hash
        @_params_hash = super

        # if we see what looks like JSON data, but have no Content-Type header...
        #
        if request.content_type.nil? or request.content_type == ''
          check_for_content_type_mismatch
        else
          content_type_header = request.content_type.split ';'
          if content_type_header.include? JSON_CONTENT_TYPE
            begin
              json_params_hash = JSON.parse request.body.read
              @_params_hash.merge! json_params_hash unless json_params_hash.nil?
            rescue JSON::ParserError => e
              begin
                msg = e.message.match(/\d+: (.+)/).captures.first
              rescue NoMethodError => noe
                msg = e.message
              end
              response.error = {
                type: 'json_parse_error',
                message: "could not process JSON: #{msg}",
                code: 400
              }
              halt
            end

            request.body.rewind
          else
            check_for_content_type_mismatch
          end
        end

        if settings.respond_to? :arrayified_params and settings.arrayified_params
          settings.arrayified_params.each do |param_name|
            array_or_comma_sep_param param_name
          end
        end

      end
      @_params_hash.merge! @params
      @_params_hash
    end

    private

    # convert param value to `Array` if String
    #
    #   * formencoded name
    #       (ex: tags[]=foo&tags[]=bar => ['foo', 'bar'])
    #   * JSON POST body Array type
    #       (ex: { "tags": ["foo", "bar"] } => ['foo', 'bar'])
    #   * formencoded comma-separated
    #       (ex: tags=foo%2Cbar => ['foo', 'bar'])
    #   * JSON POST body comma-separated
    #       (ex: { "tags": "foo,bar"] } => ['foo', 'bar'])
    #
    def array_or_comma_sep_param param_name
      if @_params_hash[param_name] and String === @_params_hash[param_name]
        @_params_hash[param_name] = @_params_hash[param_name].split ','
      end
    end

    # halt with a contentTypeMismatch error
    #
    def check_for_content_type_mismatch
      body = request.body.read
      request.body.rewind
      if body =~ /^[\{\[].*[\}\]]$/
        response.error = {
          type: 'content_type_mismatch',
          message: 'Request looks like JSON but Content-Type header was not set to application/json',
          code: 400
        }
        halt
      end
    end

  end
end
