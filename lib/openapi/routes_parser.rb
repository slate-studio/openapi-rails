module Openapi
  class RoutesParser
    require 'action_dispatch/routing/inspector'

    attr_accessor :routes

    def initialize(controller)
      @controller = controller
      @routes = []

      formatter = ActionDispatch::Routing::ConsoleFormatter.new
      @routes_table = routes_inspector.format(formatter, controller_slug)

      parse!
    end

    private

    def rails_routes
      Rails.application.routes.routes
    end

    def routes_inspector
      ActionDispatch::Routing::RoutesInspector.new(rails_routes)
    end

    def controller_slug
      @controller.
        to_s.
        underscore.
        gsub('::', '/').
        gsub('_controller','')
    end

    def parse!
      @routes_table = @routes_table.split("\n")
      @routes_table.shift

      @routes_table.each do |row|
        row.remove! ' {:format=>:json}'
        action = row.sub(/.*?#/, '')
        route  = row.split(' ').reverse
        path   = route[1].gsub('(.:format)','')
        method = route[2].underscore

        @routes << [method, path, action]
      end
    end
  end
end
