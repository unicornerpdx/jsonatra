jsonatra
========

This is a very opinionated gem. Some of its strongly held views:

* [Sinatra](http://sinatrarb.com) is the BEST.
* JSON is awesome!
* REST is fo' suckas.
* HTTP status codes are for **transport**!

To that end, this gem subclasses `Sinatra::Base` and `Sinatra::Response` adding
some helpful defaults to achieve the following goals:

* always respond with JSON, route blocks' return hashes are automatically converted
* all GET routes also respond to POST for large query values
* always supply CORS headers
* short-circuit OPTIONS requests
* *application* errors (i.e. param validation) should still 200, respond with error object
* 404s still 404 with a JSON body
* have handy error helpers

example `config.ru`:

```ruby
require 'jsonatra'

class Foo < Jsonatra::Base

  configure do
    set :arrayified_params, [:foos]
  end

  get '/hi' do
    { hello: "there", foos: params[:foos] }
  end

  get '/error' do
    param_error :foo, 'type', 'message' unless params[:foo]
    { you: "shouldn't", see: "this", unless: "foo" }
  end

  get '/halt_on_error' do
    param_error :foo, 'type', 'message' unless params[:foo]
    param_error :bar, 'type', 'message' unless params[:bar]

    # since errors in the response always take precendence,
    # halt if you need to just stop now
    #
    halt if response.error?

    { you: "shouldn't", see: "this", unless: "foo", and: "bar" }
  end

end

map '/' do
  run Foo
end
```

The above would respond like this:

#### http://localhost:9292/hi?foos=bars,bats

```
< HTTP/1.1 200 OK
< Content-Type: application/json;charset=utf-8
< Access-Control-Allow-Origin: *
< Access-Control-Allow-Methods: GET, POST
< Access-Control-Allow-Headers: Accept, Authorization, Content-Type, Origin

# ...

{"hello":"there","foos":["bars","bats"]}
```

#### http://localhost:9292/hi?foos[]=bars&foos[]=bats

```javascript
{
  "hello": "there",
  "foos": [
    "bars",
    "bats"
  ]
}
```

#### http://localhost:9292/error

```javascript
{
  "error": {
    "type": "invalidInput",
    "message": "invalid parameter or parameter value",
    "parameters": {
      "foo": [
        {
          "type": "type",
          "message": "message"
        }
      ]
    }
  }
}
```

#### http://localhost:9292/error?foo=bar

```javascript
{
  "you": "shouldn't",
  "see": "this",
  "unless": "foo"
}
```

#### http://localhost:9292/halt_on_error

```javascript
{
  "error": {
    "type": "invalidInput",
    "message": "invalid parameter or parameter value",
    "parameters": {
      "foo": [
        {
          "type": "type",
          "message": "message"
        }
      ],
      "bar": [
        {
          "type": "type",
          "message": "message"
        }
      ]
    }
  }
}
```
