# frozen_string_literal: true

require_relative "../../lib/twilight_struggle_api_authentication"
require_relative "../../lib/twilight_struggle_api_schema"

# Renders committee's schema-validation rejections in our API's error shape
# (`{errors: [...]}`, 422). Defined here rather than under app/ because config
# initializers run before app autoloading is available.
class SchemaValidationError < Committee::ValidationError
  def error_body
    {errors: [message]}
  end

  def render
    [
      422,
      {"Content-Type" => "application/json"},
      [JSON.generate(error_body)]
    ]
  end
end

Rails.application.config.middleware.use(TwilightStruggleApiAuthentication)

# coerce_form_params is misnamed on the OpenAPI 3 driver — it governs the whole
# request body, and it defaults to true, which silently casts a JSON `"7"` into
# the integer the schema asks for. We want a typed contract, not a forgiving one.
Rails.application.config.middleware.use(
  Committee::Middleware::RequestValidation,
  schema: TwilightStruggleApiSchema.driver,
  prefix: "/api/twilight-struggle/v1",
  coerce_form_params: false,
  error_class: SchemaValidationError
)
