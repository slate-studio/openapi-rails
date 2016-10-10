module Openapi
  class Engine < ::Rails::Engine
    initializer 'openapi.assets.precompile', group: :all do |app|
      app.config.assets.precompile += %w(openapi/print.css
                                         openapi/reset.css
                                         openapi/logo_small.png
                                         openapi/favicon-32x32.png
                                         openapi/favicon-16x16.png)
    end
  end

  class Railtie < Rails::Railtie
    initializer 'openapi.builders', after: :load_config_initializers do
      Rails.application.reload_routes!

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
    end
  end
end
