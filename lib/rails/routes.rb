module ActionDispatch
  module Routing
    class Mapper
      def crud(*options, &block)
        options << { except: %w(new edit), defaults: { format: :json } }
        resources(*options, &block)
      end

      def mount_openapi_documentation
        get :openapi, to: 'openapi#index'
      end

      def mount_openapi_specification(options={})
        name = options[:name] || :default
        get :spec, to: '/openapi#spec',
                   defaults: { format: :json, name: name }
      end
    end
  end
end
