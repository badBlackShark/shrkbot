# frozen_string_literal: true

require "prosopite"

# Scoped to request specs while the backend N+1 backlog is burned down.
RSpec.configure do |config|
  config.before(:each, type: :request) do
    Prosopite.scan
  end

  config.after(:each, type: :request) do
    Prosopite.finish
  end
end

Prosopite.raise = true
Prosopite.rails_logger = false
