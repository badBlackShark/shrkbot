# frozen_string_literal: true

RSpec.shared_context "without demand sources" do
  around do |example|
    sources = Integrations::Watch.demand_sources
    Integrations::Watch.demand_sources = []
    example.run
  ensure
    Integrations::Watch.demand_sources = sources
  end
end
