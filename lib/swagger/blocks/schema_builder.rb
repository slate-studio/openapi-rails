module Swagger
  module Blocks
    module SchemaBuilder
      extend ActiveSupport::Concern

      SUPPORTED_TYPES = %w(Mongoid::Boolean
                           BSON::ObjectId
                           Object
                           Time
                           String
                           Integer
                           Array
                           Date
                           Symbol).freeze

      def get_required_fields(model_class)
        presence_validators = model_class.
          validators.
          select { |v| v.class == Mongoid::Validatable::PresenceValidator }

        required_fields = presence_validators.map { |v| v.attributes.first }
        required_fields << '_id'
        required_fields
      end

      def build_model_schema(model_class, include_only_required_fields=false)
        required_fields = get_required_fields(model_class)

        key :required, required_fields

        model_class.fields.each do |name, options|
          type = options.type.to_s
          defaul_value = options.options[:default]

          next unless SUPPORTED_TYPES.include?(type)

          if include_only_required_fields
            next if name == '_id'
            next unless required_fields.include?(name.to_sym)
          end

          property name do
            case type
            when 'Symbol'
              klass = options.options[:klass].to_s
              constant = name.sub('_', '').upcase
              values = "#{klass}::#{constant}".constantize

              key :type, :string
              key :enum, values

            when 'Array'
              key :type, :array
              # TODO: autodetect type of Array Item
              items do
                key :type, :string
              end

            when 'BSON::ObjectId'
              key :type, :string
              key :format, :uuid

            when 'Date'
              key :type, :string
              key :format, :date

            when 'Time'
              key :type, :string
              key :format, 'date-time'

            when 'Mongoid::Boolean'
              key :type, :boolean
              key :default, defaul_value

            when 'Integer'
              key :type, :integer
              key :default, defaul_value.to_i

            else
              key :type, :string
              key :default, defaul_value.to_s

            end
          end
        end
      end
    end
  end
end
