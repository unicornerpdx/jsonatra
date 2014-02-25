require 'sinatra/base'
require 'json'

require 'jsonatra/response'
require 'jsonatra/helpers/error'
require 'jsonatra/helpers/params'

module Jsonatra

  ACCESS_CONTROL_HEADERS = {
    'Access-Control-Allow-Origin' => '*',
    'Access-Control-Allow-Methods' => 'GET, POST',
    'Access-Control-Allow-Headers' => 'Accept, Authorization, Content-Type, Origin'
  }

  class Base < Sinatra::Base

    helpers ErrorHelpers
    helpers ParamsHelpers

    # copied here so we can override Response.new with Jsonatra::Response.new
    #
    # https://github.com/sinatra/sinatra/blob/master/lib/sinatra/base.rb#L880
    #
    def call!(env) # :nodoc:
      @env      = env
      @request  = ::Sinatra::Request.new(env)
      @response = ::Jsonatra::Response.new
      @params   = indifferent_params(@request.params)
      template_cache.clear if settings.reload_templates
      force_encoding(@params)

      @response['Content-Type'] = nil
      invoke { dispatch! }
      invoke { error_block!(response.status) } unless @env['sinatra.error']

      unless @response['Content-Type']
        if Array === body and body[0].respond_to? :content_type
          content_type body[0].content_type
        else
          content_type :html
        end
      end

      @response.finish
    end

    configure do
      disable :show_exceptions
      disable :protection
    end

    before do

      # grok access control headers
      #
      achs = begin
               self.access_control_headers
             rescue NoMethodError
               ACCESS_CONTROL_HEADERS
             end

      # immediately return on OPTIONS
      #
      if request.request_method == 'OPTIONS'
        halt [200, achs, '']
      end

      # allow origin, oauth from everywhere
      #
      achs.each {|k,v| headers[k] = v}

      # default to Content-Type to JSON, or javascript if request is JSONP
      #
      content_type :json
      unless params[:callback].nil? or params[:callback] == ''
        halt param_error(:callback, :invalid, 'invalid callback') if params[:callback].index('"')
        response.jsonp_callback = params[:callback]
        content_type :js
      end

    end

    after do
      if settings.respond_to? :camelcase_error_types? and settings.camelcase_error_types?
        response.camelcase_error_types if response.error?
      end
    end

    error do
      response.error = {
        type: :unexpected,
        message: 'An unexpected error has occured, please try your request again later'
      }
    end

    # sinatra installs special handlers during development
    # this runs the "real" `not_found` block instead
    #
    error(Sinatra::NotFound){ not_found } if development?

    # set error values for JSON 404 response body
    #
    not_found do
      response.error = {
        type: :not_found,
        message: "The requested path was not found: #{request.path}"
      }
    end

  end

end


class String
  # ripped from:
  # https://github.com/rails/rails/blob/master/activesupport/lib/active_support/inflector/methods.rb
  #
  unless instance_methods.include? :camelcase
    def camelcase
      string = self.sub(/^(?:(?=\b|[A-Z_])|\w)/) { $&.downcase }
      string.gsub!(/(?:_|(\/))([a-z\d]*)/i) { "#{$1}#{$2.capitalize}" }
      string.gsub!('/', '::')
      string
    end
  end

  unless instance_methods.include? :blank?
    alias_method :blank?, :empty?
  end
end

class NilClass
  unless instance_methods.include? :blank?
    def blank?; true; end
  end
end

class Numeric
  unless instance_methods.include? :blank?
    def blank?; false; end
  end
end

class Symbol
  unless instance_methods.include? :camelcase
    def camelcase
      self.to_s.camelcase.to_sym
    end
  end
end
