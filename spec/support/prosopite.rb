# frozen_string_literal: true

require "prosopite"

RSpec.configure do |config|
  config.before(:each) do
    Prosopite.scan
  end

  config.after(:each) do
    Prosopite.finish
  end
end

Prosopite.raise = true
Prosopite.rails_logger = false

# Rejected finding: the tournament-tree walk queries once per chain level, not once per row.
Prosopite.allow_stack_paths = ["app/models/twilight_struggle/administered_servers.rb"]
