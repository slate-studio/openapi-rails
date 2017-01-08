<img src="http://www.kra.vc/_Media/swagger-logo.png" align="right" width="100px" />

[![Gem Version](https://badge.fury.io/rb/openapi-rails.svg)](https://badge.fury.io/rb/openapi-rails)

# OpenAPI

CRUD interface for Rails models with OpenAPI ([Swagger](http://swagger.io/))
specification support and [Swagger UI](http://swagger.io/swagger-ui/)
integration.

**This gem supports only Mongoid, for other ORMs RPs are welcome.**

[Demo](https://openapi-demo1.herokuapp.com/openapi#/Books) project for basic `openapi-rails` integration.

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

Add `Api::ProjectsController` to `config/initializer/openapi.rb` controllers
arrays of the default configuration:

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

Meta information about mapped actions and model fields is pulled automatically
on project initialization. Changes in `routes.rb` or models would require server
restart to be reflected in documentation.

In documentation interface for `create` and `update` actions request `Example
Value` includes only required fields. Other model fields should be added
manually.


## Supported Features

Following features are supported out of the box:

  - has_scope via [has_scope](https://github.com/plataformatec/has_scope)
  - search via [mongoid-search](https://github.com/mauriciozaffari/mongoid_search)
  - version via [mongoid-history](https://github.com/aq1018/mongoid-history)
  - `CSV` format for `index` action, requires `.csv` format to be added to the
    request url, e.g. `/api/posts.csv`.


## Customization

In the controller there is a way override default behaviour with helpers:

  - `paginates_per(number)` — set page size (default `50`) for `index` action
  - `resource_class(klass)` — set model class manually
  - `def resource_params` — override default method that allows everything

Helpers to customize specification build:

  - `spec_params(options)`

Supported specification `options`:
  - `collection_name` —
  - `resource_name` —
  - `resource_class` —
  - `except_actions` —
  - `relative_path` —


## Custom Actions

Mapped custom actions (not CRUD) will add a log message on server start that
controller misses specification. As a result they are not added to
documentation.

Specification for custom methods should be added manually. Check out
[Swagger Blocks](https://github.com/fotinakis/swagger-blocks) gem or
[specification builder](https://github.com/slate-studio/openapi-rails/blob/master/lib/openapi/mongoid/spec_builder.rb) code for DSL reference.

Here is an example of custom method specification:

```ruby
module Api
  class ProjectsController < BaseController
    def custom_resource_action
      # TODO: Method implemetation goes here.
    end

    swagger_path "/projects/{id}/custom_resource_action" do
      operation :get do
        key :tags,        ["Projects"]
        key :summary,     'Show extra details'
        key :operationId, "showExtraProjectDetailsById"
        key :produces,    %w(application/json)

        parameter do
          key :name,     :id
          key :type,     :string
          key :in,       :path
          key :required, true
        end

        response 200 do
          schema do
            key :'$ref', "Project"
          end
        end
      end
    end
  end
end
```


## Multiple APIs

There is a clean way to provide multiple APIs or API versions.

Here is an example of setting up two API versions:

`config/routes.rb`:

```ruby
Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      crud :projects
      mount_openapi_specification name: :v1
    end

    namespace :v2 do
      crud :projects
      mount_openapi_specification name: :v2
    end
  end

  mount_openapi_documentation
end
```

`config/initializer/openapi.rb`:

```ruby
Openapi.configure do |config|
  config.apis = {
    v1: {
      title: 'Version 1',
      description: 'Legacy API version, please check out Version 2.',
      version: '1.0',
      base_path: '/api/v1',
      controllers: [Api::V1::ProjectsController]
    },
    v2: {
      title: 'Version 2',
      description: 'Latest stable API version.',
      version: '2.0',
      base_path: '/api/v2',
      controllers: [Api::V2::ProjectsController]
    }
  }
end
```

Controllers with custom logic would be placed at `app/controllers/api/v1` and
`app/controllers/api/v2` modules.

![OpenAPI Rails — Multiple versions demo](https://d3vv6lp55qjaqc.cloudfront.net/items/3J200Q0m2m0V2m0Q3V2i/openapi-rails-multiple-versions.png)


## Related Documents

  - [OpenAPI ❤️ Rails](http://www.kra.vc/openapi-rails) — tutorial for setting
  up a new rails project with OpenAPI support.


## Contributors

 - [Alexander Kravets](http://www.kra.vc)
 - [Denis Popov](https://github.com/DenisPopov15)

If you have any ideas or questions please feel free to reach out! PRs are
welcome, tests are on the roadmap.


`OpenAPI Rails` gem is maintained and funded by [Slate Studio LLC](https://www.slatestudio.com).
