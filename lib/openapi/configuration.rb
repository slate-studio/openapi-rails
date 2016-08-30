module Openapi
  module Configuration
    attr_accessor :apis

    def configure
      yield self
    end

    def self.extended(base)
      base.set_default_configuration
    end

    def set_default_configuration
      self.apis = {}
    end
  end
end
