module Openapi
  module Configuration
    attr_accessor :apis
    attr_accessor :has_specs

    def configure
      yield self
    end

    def self.extended(base)
      base.set_default_configuration
    end

    def set_default_configuration
      self.apis = {}
      self.has_specs = false
    end
  end
end
