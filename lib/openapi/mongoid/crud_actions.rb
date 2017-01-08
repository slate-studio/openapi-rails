module Openapi
  module Mongoid
    module CrudActions
      extend ActiveSupport::Concern

      class_methods do
        def resource_class(klass)
          self.crud_resource_class = klass
        end

        def paginates_per(number)
          self.crud_per_page = number
        end
      end

      included do
        respond_to :json
        respond_to :csv, only: %w(index)

        class_attribute :crud_resource_class
        class_attribute :crud_per_page

        ## Actions

        def index
          @chain = default_scope

          apply_scopes_to_chain!
          search_filter_chain!
          paginate_chain!
          set_index_headers!

          respond_to do |format|
            format.json { render json: @chain.as_json(json_config) }
            format.csv  { render csv: @chain }
          end
        end

        def show
          @object = find_object
          set_object_version!
          render json: @object.as_json(json_config)
        end

        def create
          @object = build_object

          if @object.save
            render json: @object.as_json(json_config), status: :created

          else
            log_errors @object.errors
            render json: @object.errors, status: :unprocessable_entity

          end
        end

        def update
          @object = find_object
          if @object.update_attributes(resource_params)
            render json: @object.as_json(json_config)

          else
            log_errors @object.errors
            render json: @object.errors, status: :unprocessable_entity

          end
        end

        def destroy
          @object = find_object

          if @object.destroy
            render nothing: true, status: :no_content

          else
            log_errors @object.errors
            render json: @object.errors, status: :unprocessable_entity

          end
        end

        def response_config
          config  = {}
          fields  = params[:fields]
          methods = params[:methods]

          if fields
            only_fields = fields.split(',').select do |field_name|
              resource_class.fields.has_key?(field_name)
            end
            config[:only] = only_fields unless only_fields.empty?
          end

          if methods
            include_methods = methods.split(',').select do |method_name|
              method = method_name.to_sym
              resource_class.instance_methods(false).include?(method)
            end
            config[:methods] = include_methods unless include_methods.empty?
          end

          config
        end
        alias csv_config response_config
        alias json_config response_config

        ## Helpers

        def log_errors(errors)
          if Rails.env.development?
            logger.info "Errors:\n  #{errors.to_h}"
          end
        end

        def resource_class
          @resource_class ||= self.class.crud_resource_class
          @resource_class ||= self.class.
                                   to_s.
                                   split('::').
                                   last.
                                   sub(/Controller$/, '').
                                   singularize.
                                   constantize
        end

        def default_scope
          resource_class
        end

        def find_object
          resource_class.find(params[:id])
        end

        def build_object
          resource_class.new(resource_params)
        end

        def support_version?
          @object.respond_to?(:undo, true)
        end

        def set_object_version!
          version = params[:version]
          if version && support_version? && version.to_i != @object.version
            @object.undo(nil, from: version.to_i + 1, to: @object.version)
            @object.version = version
          end
        end

        def apply_scopes_to_chain!
          @chain = apply_scopes(@chain)
        end

        def support_search?
          @chain.respond_to?(:search, true)
        end

        def search_filter_chain!
          query = params[:search] || ''
          if !query.empty? && support_search?
            normalized_query = query.to_s.downcase
            @chain = @chain.search(normalized_query, match: :all)
          end
        end

        def page
          @page ||= (params[:page] || 1).to_i
        end

        def per_page
          @per_page ||= begin
            value = params[:perPage].try(:to_i)
            if value.nil?
              self.class.crud_per_page || 25
            elsif value == 0
              25
            else
              value
            end
          end
        end

        def paginate_chain!
          @unpaginated_chain = @chain
          @chain = @chain.skip((page - 1) * per_page).limit(per_page)
        end

        def last_page?(total_number)
          total_number <= (page - 1) * per_page + per_page
        end

        def set_index_headers!
          unpaginated_chain_size = @chain.count
          response.headers['X-Page'] = page
          response.headers['X-Total-Count'] = unpaginated_chain_size
          response.headers['X-Pages-Count'] = (unpaginated_chain_size.to_f / per_page).ceil
          response.headers['X-Per-Page']    = per_page

          unless last_page?(unpaginated_chain_size)
            response.headers['X-Next-Page'] = page + 1
          end
        end

        def resource_params
          permitted_params
        end

        # NOTE: here we permit all parameters for ease of development,
        #       before release this method should be overriden to allow only
        #       permitted parameters.
        def permitted_params
          logger.warn "#{self}: please override `permitted_params` method."
          params.require(resource_request_name).permit!
        end

        def resource_request_name
          resource_class.
            to_s.
            underscore.
            gsub('/', '_').
            gsub('::', '_')
        end
      end
    end
  end
end
