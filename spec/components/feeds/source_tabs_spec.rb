# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Feeds::SourceTabs do
  include_context "component view context"

  subject(:document) { Nokogiri::HTML.fragment(described_class.new(server_configuration:, plugin_key: :twitch, selected:).render_in(view_context)) }

  let(:server_configuration) { create(:server_configuration) }
  let(:selected) { nil }
  let(:panels) { document.css("[data-option-panels-target=panel]").to_h { |panel| [panel["data-value"], panel] } }

  it "offers a tab per source and opens the first" do
    expect(document.css("[role=radio]").map { |tab| [tab.text, tab["aria-checked"]] }).to eq([["Channels", "true"], ["Categories", "false"]])
    expect(panels.transform_values { |panel| panel.key?("hidden") }).to eq("twitch" => false, "twitch_category" => true)
  end

  it "switches panels through the option-panels controller" do
    expect(document.at_css("[data-controller=option-panels] input[name=tab]")["data-action"]).to eq("input->option-panels#show")
  end

  it "puts each source's own list in its panel" do
    expect(panels.fetch("twitch").text).to include("No channels yet")
    expect(panels.fetch("twitch_category").text).to include("No categories yet")
  end

  context "when a source's tab is selected" do
    let(:selected) { "twitch_category" }

    it "shows only that panel" do
      expect(panels.transform_values { |panel| panel.key?("hidden") }).to eq("twitch" => true, "twitch_category" => false)
      expect(document.at_css("[role=radio][aria-checked=true]").text).to eq("Categories")
    end
  end

  context "when the selected tab is not one of the sources" do
    let(:selected) { "bogus" }

    it "opens the first" do
      expect(document.at_css("[role=radio][aria-checked=true]").text).to eq("Channels")
    end
  end

  context "with a plugin that has one source" do
    subject(:document) { Nokogiri::HTML.fragment(described_class.new(server_configuration:, plugin_key: :steam).render_in(view_context)) }

    it "renders its list without tabs" do
      expect(document.css("[role=radio]")).to be_empty
      expect(document.text).to include("No games yet")
    end
  end
end
