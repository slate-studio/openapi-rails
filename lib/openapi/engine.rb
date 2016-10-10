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
end
