# frozen_string_literal: true

RSpec.shared_context "with a bespoke plugin definition" do
  let(:bespoke_definition) do
    PluginCatalog::Definition.new(
      key: :bespoke_thing,
      name: "Bespoke Thing",
      description: "Owner-granted.",
      bespoke: true
    )
  end
  let(:catalog_definitions) { PluginCatalog::DEFINITIONS + [bespoke_definition] }

  before do
    stub_const("PluginCatalog::DEFINITIONS", catalog_definitions)
  end
end
