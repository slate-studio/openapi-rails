module Api
  class BaseController < ActionController::Base
    include Openapi::Mongoid::CrudActions
    include Openapi::Mongoid::SpecBuilder
  end
end
