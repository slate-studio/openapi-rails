<img src="http://www.kra.vc/_Media/swagger-logo.png" align="right" width="120px" />

[![Gem Version](https://badge.fury.io/rb/openapi-rails.svg)](https://badge.fury.io/rb/openapi-rails)

# OpenAPI

CRUD interface for Rails models with OpenAPI ([Swagger](http://swagger.io/))
specification support and [Swagger UI](http://swagger.io/swagger-ui/)
integration.

**This gem supports only Mongoid, for other ORMs RPs are welcome.**


## Installation

Add to your `Gemfile`:

```ruby
gem 'openapi-rails'
```

For new projects we recommend to run generator to create basic setup:

```
rake g openapi:config
```

If you have an existing project, please look through this readme file first to
get an idea of how it works.

Generator is creating configuration file `config/initializer/openapi.rb` with
default `/api` configuration and base controller `app/controllers/api/base_controlle.rb` that provides CRUD actions and specification builder.


## Usage

*Here projects API considered to be available at `/api`. Please check out
[Multiple APIs](#multiple-apis) section for other options.*

To add `CRUD` interface for the `Project` model create an empty controller that
inherits from `BaseController` at `app/controllers/api/projects_controller.rb`:

```ruby
module Api
  class ProjectsController < BaseController
  end
end
```

Map controller with `crud` helper, mount specification and documentation in
`routes.rb`:

```ruby
Rails.application.routes.draw do
  namespace :api do
    crud :projects
    # Mount OpenAPI specification for API
    mount_openapi_specification name: :default
  end

  # Mount Swagger UI documentation for API
  mount_openapi_documentation
end
```

Check out the `config/initializer/openapi.rb` configuration and add new
controller to be included in JSON specification:

```ruby
Openapi.configure do |config|
  config.apis = {
    default: {
      title: 'Default',
      description: '',
      version: '1.0',
      base_path: '/api',
      controllers: [Api::ProjectsController]
    }
  }
end
```

Restart develoment server and open [http://localhost:3000/openapi](http://localhost:3000/openapi) where API documentation is served.

![OpenAPI Rails Demo](https://d3vv6lp55qjaqc.cloudfront.net/items/262y2S3Q3N0u14160a20/openapi-rails-demo.png)


## CSV


## Customization

 - json
 - has_scope
 - per_page
 - resource_class


## Custom Actions

 - warning
 - building spec for custom actions


## Multiple APIs

 - configuration options


## Contributors

 - Alexander Kravets
 - Denis Popov


`OpenAPI Rails` gem is maintained and funded by [Slate Studio LLC](https://www.slatestudio.com)
