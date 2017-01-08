module Openapi
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      unless Openapi.has_specs
        puts "[Openapi::Middleware] Building openapi specs..."
        Openapi.apis.each do |name, config|
          base_path = config[:base_path] || '/api'

          config[:controllers].each do |controller|
            controller.build_openapi_specification(base_path: base_path)
          end

          name = name.to_s.titleize.remove(' ')
          root_klass_name = "#{name}SwaggerRootController"
          klass = Object.const_set root_klass_name, Class.new(SwaggerRoot)
          klass.build_specification(config, config[:controllers])

          config[:controllers].push klass
        end

        Openapi.has_specs = true
      end

      @app.call(env)
    end
  end
end
