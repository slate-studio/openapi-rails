require 'csv'
require 'action_controller/metal/renderers'

ActionController::Renderers.add :csv do |objects, options|
  return '' unless objects.first

  object_klass = objects.first.class

  return '' unless object_klass.respond_to? :fields

  columns = object_klass.fields.keys
  csv_options = self.csv_config || {}

  if csv_options
    if csv_options.key?(:only)
      columns &= csv_options[:only].map(&:to_s)
    end

    if csv_options.key?(:except)
      columns -= csv_options[:except].map(&:to_s)
    end

    if csv_options.key?(:methods)
      columns += csv_options[:methods].map(&:to_s)
    end
  end

  str = CSV.generate do |row|
    row << columns
    objects.each do |obj|
      row << columns.map { |c| obj.send(c) }
    end
  end

  return str
end
