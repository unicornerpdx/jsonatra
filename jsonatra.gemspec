# -*- encoding: utf-8 -*-
require File.expand_path('../lib/jsonatra/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Kenichi Nakamura", "Aaron Parecki"]
  gem.email         = ["kenichi.nakamura@gmail.com", "aaron@parecki.com"]
  gem.description   = gem.summary = "JSON API extension for Sinatra"
  gem.homepage      = "https://github.com/esripdx/jsonatra"
  gem.files         = `git ls-files | grep -Ev '^(myapp|examples)'`.split("\n")
  gem.test_files    = `git ls-files -- test/*`.split("\n")
  gem.name          = "jsonatra"
  gem.require_paths = ["lib"]
  gem.version       = Jsonatra::VERSION
  gem.license       = 'apache'
  gem.add_dependency 'sinatra'
end
