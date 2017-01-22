module Openapi
  class SwaggerRoot
    include Swagger::Blocks

    def self.build_specification(config, controller_classes)
      schema = Rails.env.production? ? 'https' : 'http'

      swagger_root do
        key :swagger,  '2.0'
        key :host,     ENV['HOST'] || 'localhost:3000'
        key :basePath, config[:base_path] || '/api'
        key :consumes, %w(application/json)
        key :produces, %w(application/json text/csv)
        key :schemes,  [schema]

        info do
          key :title,       config[:title] || 'Default'
          key :description, config[:description] || ''
          key :version,     config[:version] || '1.0'
        end

        controller_classes.each do |c|
          tag do
            key :name, c.spec_collection_name
          end
        end
      end
    end
  end

  module Mongoid
    module SpecBuilder
      extend ActiveSupport::Concern

      CRUD_ACTIONS = %w(index create show update destroy).freeze

      included do
        include Swagger::Blocks

        class_attribute :spec_collection_name
        class_attribute :spec_resource_name
        class_attribute :spec_resource_class
        class_attribute :spec_except_actions
        class_attribute :spec_relative_path

        class_attribute :spec_base_path
      end

      class_methods do
        def spec_params(options)
          self.spec_resource_class  = options[:resource_class]
          self.spec_resource_name   = options[:resource_name]
          self.spec_collection_name = options[:collection_name]
          self.spec_relative_path   = options[:relative_path]
          self.spec_except_actions  = options[:except_actions]
        end

        def build_openapi_specification(options)
          self.spec_except_actions ||=
            []

          self.spec_base_path =
            options[:base_path]

          self.spec_relative_path ||=
            ('/' + to_s.remove(/Controller$/).gsub('::', '/').underscore).
              remove(spec_base_path)

          self.spec_resource_class ||=
            self.try(:crud_resource_class)

          self.spec_resource_class ||=
            self.to_s.
              split('::').
              last.
              sub(/Controller$/, '').
              singularize.
              constantize

          self.spec_resource_name ||=
            self.spec_resource_class.to_s.remove('::')

          self.spec_collection_name ||=
            self.spec_resource_name.pluralize

          build_openapi_definitions
          build_openapi_paths
        end

        def build_openapi_paths
          routes = Openapi::RoutesParser.new(self).routes
          build_crud_specification(routes)

          if Rails.env.development?
            warn_on_undocumented_actions(routes)
          end
        end

        def build_openapi_definitions
          collection_name        = spec_collection_name
          resource_class         = spec_resource_class
          resource_name          = spec_resource_name
          resource_property_name = resource_name.underscore.to_sym

          swagger_schema resource_name do
            build_model_schema(resource_class)

            resource_class.relations.each do |key, relation|
              relation_type = relation.relation.to_s

              if relation_type.include? 'Mongoid::Relations::Embedded'
                relation_name =
                  relation.name.to_s.singularize.titleize.remove(' ')

                # TODO: This is not accurate, class might be in the same
                #       namespace as related.
                # namespace = resource_class.to_s.split('::')[0...-1].join('::')
                # generated_embedded_resource_class_name = [namespace, relation_name].join('::')

                # TODO: Add error handler in case class is not guessed here.
                embedded_resource_class =
                  (relation.class_name || relation_name).constantize

                if relation_type.include? 'Many'
                  property relation.name.to_s, type: :array do
                    items do
                      build_model_schema(embedded_resource_class)
                    end
                  end

                else
                  property relation.name.to_s.singularize, type: :object do
                    build_model_schema(embedded_resource_class)
                  end

                end
              end
            end
          end

          swagger_schema "#{resource_name}Input" do
            property resource_property_name, type: :object do
              build_model_schema(resource_class, true)
            end
          end
        end

        def build_crud_specification(routes)
          name        = spec_resource_name
          sym_name    = name.underscore.to_sym
          plural_name = spec_collection_name
          path        = spec_relative_path
          scopes      = try(:scopes_configuration) || []
          actions     = routes.map {|r| r[2]}.uniq
          json_mime   = %w(application/json)

          include_index   = actions.include?('index') &&
                            !spec_except_actions.include?('index')
          include_create  = actions.include?('create') &&
                            !spec_except_actions.include?('create')
          include_show    = actions.include?('show') &&
                            !spec_except_actions.include?('show')
          include_update  = actions.include?('update') &&
                            !spec_except_actions.include?('update')
          include_destroy = actions.include?('destroy') &&
                            !spec_except_actions.include?('destroy')

          include_collection_actions =
            (include_index || include_create)
          include_resource_actions =
            (include_show || include_update || include_destroy)

          support_search = spec_resource_class.methods.include?(:search)

          if include_collection_actions
            swagger_path path do

              if include_index
                operation :get do
                  key :tags,        [plural_name]
                  key :summary,     "index#{plural_name}"
                  key :operationId, "index#{plural_name}"
                  key :produces,    json_mime

                  parameter do
                    key :name,        :page
                    key :description, 'Page number'
                    key :type,        :integer
                    key :format,      :int32
                    key :in,          :query
                    key :required,    false
                  end

                  parameter do
                    key :name,        :perPage
                    key :description, 'Items per page'
                    key :type,        :integer
                    key :format,      :int32
                    key :in,          :query
                    key :required,    false
                  end

                  parameter do
                    key :name,     :fields
                    key :in,       :query
                    key :required, false
                    key :description, 'Return exact model fields'
                    key :type,        :array
                    items do
                      key :type, :string
                    end
                  end

                  parameter do
                    key :name,        :methods
                    key :description, 'Include model methods'
                    key :in,          :query
                    key :required,    false
                    key :type,        :array
                    items do
                      key :type, :string
                    end
                  end

                  if support_search
                    parameter do
                      key :name,        :search
                      key :description, 'Search query string'
                      key :type,        :string
                      key :in,          :query
                      key :required,    false
                    end
                  end

                  scopes.each do |k, config|
                    scope_name = config[:as]
                    scope_type = config[:type]

                    if scope_type == :default
                      scope_type = :string
                    end

                    parameter do
                      key :name,     scope_name
                      key :type,     scope_type
                      key :in,       :query
                      key :required, false

                      if scope_type == :integer
                        key :format, :int32
                      end
                    end
                  end

                  response 200 do
                    key :description, 'Success'
                    schema type: :array do
                      items do
                        key :'$ref', name
                      end
                    end
                  end
                end
              end

              if include_create
                operation :post do
                  key :tags,        [plural_name]
                  key :summary,     "create#{name}"
                  key :operationId, "create#{name}"
                  key :produces,    json_mime

                  parameter do
                    key :name,     "body{#{sym_name}}"
                    key :in,       :body
                    key :required, true
                    schema do
                      key :'$ref', "#{name}Input"
                    end
                  end

                  parameter do
                    key :name,     :fields
                    key :in,       :query
                    key :required, false
                    key :description, 'Return exact model fields'
                    key :type,        :array
                    items do
                      key :type, :string
                    end
                  end

                  parameter do
                    key :name,        :methods
                    key :description, 'Include model methods'
                    key :in,          :query
                    key :required,    false
                    key :type,        :array
                    items do
                      key :type, :string
                    end
                  end

                  response 201 do
                    key :description, 'Success'
                    schema do
                      key :'$ref', name
                    end
                  end
                end
              end
            end
          end

          if include_resource_actions
            swagger_path "#{path}/{id}" do

              if include_show
                operation :get do
                  key :tags,        [plural_name]
                  key :summary,     "show#{name}ById"
                  key :operationId, "show#{name}ById"
                  key :produces,    json_mime

                  parameter do
                    key :name,     :id
                    key :type,     :string
                    key :in,       :path
                    key :required, true
                  end

                  parameter do
                    key :name,     :fields
                    key :in,       :query
                    key :required, false
                    key :description, 'Return exact model fields'
                    key :type,        :array
                    items do
                      key :type, :string
                    end
                  end

                  parameter do
                    key :name,        :methods
                    key :description, 'Include model methods'
                    key :in,          :query
                    key :required,    false
                    key :type,        :array
                    items do
                      key :type, :string
                    end
                  end

                  response 200 do
                    key :description, 'Success'
                    schema do
                      key :'$ref', name
                    end
                  end
                end
              end

              if include_update
                operation :put do
                  key :tags,        [plural_name]
                  key :summary,     "update#{name}"
                  key :operationId, "update#{name}"
                  key :produces,    json_mime

                  parameter do
                    key :name,     :id
                    key :type,     :string
                    key :in,       :path
                    key :required, true
                  end

                  parameter do
                    key :name,     :fields
                    key :in,       :query
                    key :required, false
                    key :description, 'Return exact model fields'
                    key :type,        :array
                    items do
                      key :type, :string
                    end
                  end

                  parameter do
                    key :name,        :methods
                    key :description, 'Include model methods'
                    key :in,          :query
                    key :required,    false
                    key :type,        :array
                    items do
                      key :type, :string
                    end
                  end

                  parameter do
                    key :name,     "body{#{sym_name}}"
                    key :in,       :body
                    key :required, true
                    schema do
                      key :'$ref', "#{name}Input"
                    end
                  end

                  response 200 do
                    key :description, 'Success'
                    schema do
                      key :'$ref', name
                    end
                  end
                end
              end

              if include_destroy
                operation :delete do
                  key :tags,        [plural_name]
                  key :summary,     "destroy#{name}"
                  key :operationId, "destroy#{name}"

                  parameter do
                    key :name,     :id
                    key :type,     :string
                    key :in,       :path
                    key :required, true
                  end

                  response 204 do
                    key :description, 'Success'
                  end
                end
              end
            end
          end
        end

        def warn_on_undocumented_actions(routes)
          custom_routes = routes.select {|r| !CRUD_ACTIONS.include?(r[2])}
          no_spec_methods = custom_routes.select do |route|
            method = route[0].to_sym
            path = route[1].remove(spec_base_path)
            path_sym = path.gsub(/:(\w+)/, '{\1}').to_sym

            ! action_specification_exists?(method, path_sym)
          end

          unless no_spec_methods.empty?
            routes = no_spec_methods.map do |r|
              method = r[0].upcase
              path   = r[1]
              "  #{method} #{path}"
            end.join("\n")

            puts "\n#{self} misses specification for:\n#{routes}\n\n"
          end
        end

        def action_specification_exists?(method, path)
          swagger_nodes = self.send(:_swagger_nodes)
          node_map = swagger_nodes[:path_node_map]

          node_map.has_key?(path) && node_map[path].data.has_key?(method)
        end
      end
    end
  end
end
