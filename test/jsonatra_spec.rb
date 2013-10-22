require_relative './helper'

describe Jsonatra::Base do

  HI = {
    'hello' =>  'there',
    'scinot' => -122.67641415934295823498407,
    'foo' =>    42,
    'bar' =>    true,
    'baz' =>    false
  }

  before do
    mock_app do
      configure do
        set :arrayified_params, ['foos']
      end
      get('/'){}
      get('/hi'){ HI }
      get('/aps'){ {foos: params[:foos]} }
    end
  end

  describe 'basics' do

    it 'delivers empty object for nil returning routes' do
      gapapj '/' do
        r.must_equal({})
      end
    end

    it 'sets content type to json' do
      gapapj '/' do
        ct = last_response.content_type.split(';')
        ct.must_include Rack::Mime::MIME_TYPES['.json']
      end
    end

    it 'sets content type to js if callback param' do
      gapapj '/', { callback: 'foo' } do
        ct = last_response.content_type.split(';')
        ct.must_include Rack::Mime::MIME_TYPES['.js']
      end
    end

    it 'returns json from routes that return hashes' do
      gapapj '/hi' do
        r.must_equal HI
      end
    end

  end

  describe 'jsonp' do

    it 'wraps response object in func call if callback param' do
      gapapj '/', callback: 'foo' do
        last_response.body.must_equal 'foo({});'
      end
    end

    it 'errors if callback contains double quote char' do
      get '/', callback: 'foo"bar"baz'
      must_have_parameter_error_for :callback
    end

  end

  describe 'arrayified params' do

    it 'returns an array when an array is given' do
      a = ['foo', 'bar']
      get '/aps', foos: a
      r['foos'].must_equal a
      post '/aps', foos: a
      r['foos'].must_equal a
    end

    it 'returns an array when a comma-separated string is given' do
      a = ['foo', 'bar']
      get '/aps', foos: a.join(',')
      r['foos'].must_equal a
      post '/aps', foos: a.join(',')
      r['foos'].must_equal a
    end

    it 'returns nil if nothing was given' do
      get '/aps'
      r['foos'].must_be_nil
      post '/aps'
      r['foos'].must_be_nil
    end

  end

  describe 'CORS header' do

    it 'responds with headers containing an open allow origin policy' do
      [:get, :post, :options].each do |meth|
        __send__ meth, '/'
        last_response.headers.keys.must_include 'Access-Control-Allow-Origin'
        last_response.headers['Access-Control-Allow-Origin'].must_equal '*'
        last_response.headers.keys.must_include 'Access-Control-Allow-Headers'
        last_response.headers['Access-Control-Allow-Headers'].must_equal 'Accept, Authorization, Content-Type, Origin'
        last_response.headers.keys.must_include 'Access-Control-Allow-Methods'
        last_response.headers['Access-Control-Allow-Methods'].must_equal 'GET, POST'
      end
    end

  end

end
