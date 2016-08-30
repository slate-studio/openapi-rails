class OpenapiController < ActionController::Base
  respond_to :json

  def index
    @specs = Openapi.apis.map do |name, config|
      title = config[:title]
      spec_path = "#{config[:base_path]}/spec"
      [title, spec_path]
    end

    @default_specification_path = @specs.first ? @specs.first[1] : ''

    render 'index', layout: false
  end

  def spec
    name = params[:name] || :default
    config = Openapi.apis[name]
    controllers = config[:controllers]
    json_schema = Swagger::Blocks.build_root_json(controllers)

    render json: json_schema
  end
end
