require 'sinatra/base'
require 'json'

$:.push File.expand_path '..', __FILE__
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

      # default to Content-Type to JSON, or javascript if request is JSONP
      #
      content_type :json
      unless params[:callback].nil? or params[:callback] == ''
        halt param_error(:callback, :invalid, 'invalid callback') if params[:callback].index('"')
        response.jsonp_callback = params[:callback]
        content_type :js
      end

      # immediately return on OPTIONS
      #
      if request.request_method == 'OPTIONS'
        if settings.respond_to? :options_handler and Proc === settings.options_handler
          settings.options_handler.call
        else
          halt [200, ACCESS_CONTROL_HEADERS, '']
        end
      end

      # allow origin, oauth from everywhere
      #
      ACCESS_CONTROL_HEADERS.each {|k,v| headers[k] = v}

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

  class Application < Sinatra::Base
  end

end
