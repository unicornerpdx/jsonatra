ENV['RACK_ENV'] = 'test'

require 'rack/test'
require 'minitest/autorun'
require 'minitest/pride'
require 'pry'
require 'pry-nav'

require_relative '../lib/jsonatra'

include Rack::Test::Methods

def app
  @controller
end

def mock_app &block
  @controller = Sinatra.new Jsonatra::Base, &block
end

def r
  JSON.parse last_response.body
end

def get_and_post *args, &block
  get *args
  yield
  setup
  post *args
  yield
end

JSON_CT = { 'CONTENT_TYPE' => 'application/json' }
def post_json path, params = {}, headers = {}
  post path, params.to_json, headers.merge(JSON_CT)
end

def get_and_post_and_post_json path, params = {}, headers = {}, &block
  get_and_post path, params, headers, &block
  post_json path, params, headers, &block
end
alias gapapj get_and_post_and_post_json

def must_have_parameter_error_for parameter, type = :invalid, error_type = :invalidInput
  last_response.status.must_equal 200
  r['error'].wont_be_nil
  r['error']['type'].must_equal error_type.to_s
  r['error']['parameters'].wont_be_nil
  r['error']['parameters'][parameter.to_s].wont_be_empty
  r['error']['parameters'][parameter.to_s].first['type'].must_equal type.to_s
end

def must_have_header_error_for header, type = :invalid, error_type = :invalidHeader
  last_response.status.must_equal 200
  r['error'].wont_be_nil
  r['error']['type'].must_equal error_type.to_s
  r['error']['headers'].wont_be_nil
  r['error']['headers'][header.to_s].wont_be_empty
  r['error']['headers'][header.to_s].first['type'].must_equal type.to_s
end
