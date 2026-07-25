# frozen_string_literal: true

require_relative "../../lib/twilight_struggle_api_authentication"

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

# The request contract is split one file per controller under
# config/api/twilight-struggle/v1/; committee wants a single schema, so merge
# the fragments (disjoint paths + component schemas) into one document at boot.
module TwilightStruggleApiSchema
  DIR = Rails.root.join("config/api/twilight-struggle/v1")

  def self.driver
    document = {
      "openapi" => "3.0.3",
      "info" => {"title" => "shrkbot Twilight Struggle API", "version" => "1.0"},
      "paths" => {},
      "components" => {"schemas" => {}}
    }

    Dir.glob(DIR.join("*.yaml")).sort.each do |path|
      fragment = YAML.safe_load_file(path)
      merge_disjoint!(document["paths"], fragment.fetch("paths", {}), path)
      merge_disjoint!(document["components"]["schemas"], fragment.dig("components", "schemas") || {}, path)
    end

    Committee::Drivers.load_from_data(document, parser_options: {strict_reference_validation: true})
  end

  def self.merge_disjoint!(into, from, source)
    from.each do |key, value|
      raise "#{source}: #{key.inspect} is already defined by another schema fragment" if into.key?(key)

      into[key] = value
    end
  end
end

Rails.application.config.middleware.use(TwilightStruggleApiAuthentication)

Rails.application.config.middleware.use(
  Committee::Middleware::RequestValidation,
  schema: TwilightStruggleApiSchema.driver,
  prefix: "/api/twilight-struggle/v1",
  error_class: SchemaValidationError
)
