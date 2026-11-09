# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Feeds::Twitch::ModePanel do
  include_context "component view context"

  subject(:panel) { Nokogiri::HTML.fragment(described_class.new(mode: "keep", description: "It stays.", card:, hidden:, preview_label: "Look").render_in(view_context)).at_css("[data-option-panels-target=panel]") }

  let(:card) { nil }
  let(:hidden) { false }

  it "carries its mode for the option panels and shows the description" do
    expect(panel["data-value"]).to eq("keep")
    expect(panel.text).to include("It stays.")
    expect(panel.text).not_to include("Look")
  end

  context "when hidden" do
    let(:hidden) { true }

    it { expect(panel.key?("hidden")).to be(true) }
  end

  context "with a card" do
    let(:card) { Feeds::Twitch::PreviewSamples.new(watch_name: "shark", event_type: Integrations::Twitch::StreamStarted.name).switched_card }

    it "previews it under the given label" do
      expect(panel.text).to include("Look")
    end
  end
end
