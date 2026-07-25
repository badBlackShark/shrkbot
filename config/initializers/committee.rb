# frozen_string_literal: true

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

Rails.application.config.middleware.use(
  Committee::Middleware::RequestValidation,
  schema_path: Rails.root.join("config/api/twilight-struggle-v1.yaml").to_s,
  prefix: "/api/twilight-struggle/v1",
  error_class: SchemaValidationError,
  strict_reference_validation: true,
  accept_request_filter: ->(request) { request.get_header("HTTP_AUTHORIZATION").present? }
)
