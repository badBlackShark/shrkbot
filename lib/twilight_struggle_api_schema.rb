# frozen_string_literal: true

require "yaml"

# Builds the Twilight Struggle API's OpenAPI document from the per-controller
# fragments under config/api/twilight-struggle/v1/. Rails-free on purpose: the
# `document` path (schema merge) is reused by the docs-generation rake task,
# which must run without booting the app or a database.
module TwilightStruggleApiSchema
  DIR = File.expand_path("../config/api/twilight-struggle/v1", __dir__)
  PROSE_DIR = File.join(DIR, "docs")
  TAGS = ["Tournaments", "Games"].freeze

  def self.driver
    Committee::Drivers.load_from_data(document, parser_options: {strict_reference_validation: true})
  end

  def self.document
    document = {
      "openapi" => "3.0.3",
      "info" => {
        "title" => "shrkbot Twilight Struggle API",
        "version" => "1.0",
        "description" => prose("overview")
      },
      "servers" => [{"url" => "https://shrkbot.com/api/twilight-struggle/v1"}],
      "tags" => TAGS.map { |tag| {"name" => tag, "description" => prose(tag.downcase)} },
      "security" => [{"bearerAuth" => []}],
      "paths" => {},
      "components" => {
        "securitySchemes" => {"bearerAuth" => {"type" => "http", "scheme" => "bearer"}},
        "schemas" => {}
      }
    }

    Dir.glob(File.join(DIR, "*.yaml")).sort.each do |path|
      fragment = YAML.safe_load_file(path)
      merge_disjoint!(document["paths"], fragment.fetch("paths", {}), path)
      merge_disjoint!(document["components"]["schemas"], fragment.dig("components", "schemas") || {}, path)
    end

    document
  end

  def self.prose(name)
    File.read(File.join(PROSE_DIR, "#{name}.md"))
  end
  private_class_method :prose

  def self.merge_disjoint!(into, from, source)
    from.each do |key, value|
      raise "#{source}: #{key.inspect} is already defined by another schema fragment" if into.key?(key)

      into[key] = value
    end
  end
end
