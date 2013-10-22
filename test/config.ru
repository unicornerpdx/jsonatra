$:.push File.expand_path '../../lib', __FILE__
require 'jsonatra'

class Foo < Jsonatra::Base
  configure do
    set :arrayified_params, ['foos']
  end
  get '/hi' do
    { hello: "there", foos: params[:foos] }
  end
end

map '/' do
  run Foo
end
