# encoding: utf-8
module Openapi
  class ConfigGenerator < Rails::Generators::Base
    desc 'Creates OpenAPI initialization file and Api::BaseController'

    def self.source_root
      File.expand_path('../templates', __FILE__)
    end

    def create_config_file
      dest = File.join('config/initializers', 'openapi.rb')
      template 'openapi.rb', dest
    end

    def create_base_controller_file
      dest = File.join('app/controllers/api', 'base_controller.rb')
      template 'base_controller.rb', dest
    end
  end
end
