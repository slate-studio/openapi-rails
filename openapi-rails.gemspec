# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'openapi/version'
require 'date'

Gem::Specification.new do |s|
  s.name             = 'openapi-rails'
  s.summary          = 'CRUD interface for Rails models with OpenAPI (Swagger) specification support and Swagger UI integration.'
  s.homepage         = 'http://github.com/slate-studio/openapi-rails'
  s.authors          = [ 'Alexander Kravets', 'Denis Popov' ]
  s.email            = "alex@slatestudio.com"
  s.date             = Date.today.strftime('%Y-%m-%d')
  s.extra_rdoc_files = %w[ README.md ]
  s.license          = 'MIT'
  s.files            = `git ls-files`.split("\n")
  s.test_files       = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths    = [ 'lib' ]
  s.version          = Openapi::VERSION
  s.platform         = Gem::Platform::RUBY

  # DSL for pure Ruby code blocks that can be turned into JSON
  s.add_dependency 'swagger-blocks'
  # A set of Rails responders to dry up application controllers
  s.add_dependency 'responders', '~> 2.3'
  # Clean, powerful, customizable and sophisticated paginator
  s.add_dependency 'kaminari'
  # C extensions to accelerate the Ruby BSON serialization
  s.add_dependency 'bson_ext'
  # Fast streaming JSON parsing and encoding library for Ruby
  s.add_dependency 'yajl-ruby'
  # Map incoming controller parameters to named scopes in resources
  s.add_dependency 'has_scope'
end
