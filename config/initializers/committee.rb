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

Rails.application.config.middleware.use(
  Committee::Middleware::RequestValidation,
  schema: TwilightStruggleApiSchema.driver,
  prefix: "/api/twilight-struggle/v1",
  error_class: SchemaValidationError
)
