require_relative '../helper'

describe Jsonatra::ErrorHelpers do

  before do
    mock_app do
      get '/pe' do
        param_error :foo, :invalid, 'foo bar'
      end
      get '/he' do
        header_error :foo, :invalid, 'foo bar'
      end

      get '/pec' do
        param_error :foo, :invalid, 'foo bar' do |e|
          e[:code] = 401
        end
      end
      get '/hec' do
        header_error :foo, :invalid, 'foo bar' do |e|
          e[:code] = 498
        end
      end
    end
  end

  describe '404 handler' do

    it 'includes code: 404 in the json body of the response' do
      get '/not_found'
      last_response.status.must_equal 404
    end

  end

  describe 'param_error' do

    it 'creates error messages properly' do
      gapapj '/pe' do
        must_have_parameter_error_for :foo
        r['error']['parameters']['foo'].first['message'].must_equal 'foo bar'
      end
    end

    it 'can arbitrarily add to error object' do
      gapapj '/pec' do
        must_have_parameter_error_for :foo
        r['error']['code'].must_equal 401
      end
    end

  end

  describe 'header_error' do

    it 'creates error messages properly' do
      gapapj '/he' do
        must_have_header_error_for :foo
        r['error']['headers']['foo'].first['message'].must_equal 'foo bar'
      end
    end

    it 'can arbitrarily add to error object' do
      gapapj '/hec' do
        must_have_header_error_for :foo
        r['error']['code'].must_equal 498
      end
    end

  end

  describe 'camelcase_error_tyeps' do

    before do
      mock_app do
        configure do
          enable :camelcase_error_types
        end
        get '/pe' do
          param_error :foo, :snakey_snake, 'foo bar'
        end
        get '/he' do
          header_error :foo, :snakey_snake, 'foo bar'
        end
      end
    end

    it 'camelcases parameter error types' do
      gapapj '/pe' do
        must_have_parameter_error_for :foo, :snakeySnake, :invalidInput
      end
    end

    it 'camelcases header error types' do
      gapapj '/he' do
        must_have_header_error_for :foo, :snakeySnake, :invalidHeader
      end
    end

    describe 'contentTypeMismatch' do

      before do
        mock_app do
          configure do
            enable :camelcase_error_types
          end
          get '/params' do
            params
          end
        end
      end

      it 'returns an informative error if it notices JSON content without correct header' do
        post '/params', {foo: 'bar', baz: 42, bat: ['a', 1, 5.75, true]}.to_json
        r['error'].wont_be_nil
        r['error']['type'].must_equal "contentTypeMismatch"
      end

    end
  end
end
