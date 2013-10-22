require_relative '../helper'

describe Jsonatra::ParamsHelpers do

  before do
    mock_app do
      get '/params' do
        params
      end
    end
  end

  it 'returns request params same as default for GET requests' do
    get '/params', foo: 'bar', baz: 42, bat: ['a', 1, 5.75, true]
    r['foo'].must_equal 'bar'
    r['baz'].must_equal '42'
    r['bat'][0].must_equal 'a'
    r['bat'][1].must_equal '1'
    r['bat'][2].must_equal '5.75'
    r['bat'][3].must_equal 'true'
  end

  it 'returns request form encoded params same as default for POST requests' do
    post '/params', foo: 'bar', baz: 42, bat: ['a', 1, 5.75, true]
    r['foo'].must_equal 'bar'
    r['baz'].must_equal '42'
    r['bat'][0].must_equal 'a'
    r['bat'][1].must_equal '1'
    r['bat'][2].must_equal '5.75'
    r['bat'][3].must_equal 'true'
  end

  it 'parses and returns JSON data POSTed in the request body' do
    post_json '/params', foo: 'bar', baz: 42, bat: ['a', 1, 5.75, true]
    r['foo'].must_equal 'bar'
    r['baz'].must_equal 42
    r['bat'][0].must_equal 'a'
    r['bat'][1].must_equal 1
    r['bat'][2].must_equal 5.75
    r['bat'][3].must_equal true
  end

  it 'JSON data POSTed in the request body overrides default params' do
    qs = Rack::Utils.escape({ foo: 'baR', baz: 43, bat: ['A', 2, 5.76, false] })
    post_json "/params?#{qs}", foo: 'bar', baz: 42, bat: ['a', 1, 5.75, true]
    r['foo'].must_equal 'bar'
    r['baz'].must_equal 42
    r['bat'][0].must_equal 'a'
    r['bat'][1].must_equal 1
    r['bat'][2].must_equal 5.75
    r['bat'][3].must_equal true
  end

  it 'returns an informative error if it notices JSON content without correct header' do
    post '/params', {foo: 'bar', baz: 42, bat: ['a', 1, 5.75, true]}.to_json
    r['error'].wont_be_nil
    r['error']['type'].must_equal "contentTypeMismatch"

    post '/params', ['a', 1, 5.75, true].to_json
    r['error'].wont_be_nil
    r['error']['type'].must_equal "contentTypeMismatch"

    post '/params', {foo: 'bar', baz: 42, bat: ['a', 1, 5.75, true]}.to_json, {'Content-Type' => 'text/plain'}
    r['error'].wont_be_nil
    r['error']['type'].must_equal "contentTypeMismatch"

    post '/params', ['a', 1, 5.75, true].to_json, {'Content-Type' => 'text/plain'}
    r['error'].wont_be_nil
    r['error']['type'].must_equal "contentTypeMismatch"
  end

end
