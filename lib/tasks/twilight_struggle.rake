# frozen_string_literal: true

namespace :twilight_struggle do
  desc "Print the merged Twilight Struggle OpenAPI document as JSON"
  task openapi: :environment do
    puts JSON.pretty_generate(TwilightStruggleApiSchema.document)
  end
end
