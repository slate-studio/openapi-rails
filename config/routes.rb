Openapi::Engine.routes.draw do
  Openapi.apis.each do |name, config|
    base_path = config[:base_path] || '/api'

    config[:controllers].each do |controller|
      if controller.respond_to?(:build_openapi_specification)
        controller.build_openapi_specification(base_path: base_path)
      else
        raise NoMethodError, 'Restart the Rails server after changing a resource in the api routes.'
      end
    end

    name = name.to_s.titleize.remove(' ')
    root_klass_name = "#{name}SwaggerRootController"
    klass = Object.const_set root_klass_name, Class.new(Openapi::SwaggerRoot)
    klass.build_specification(config, config[:controllers])

    config[:controllers].push klass
  end
end
