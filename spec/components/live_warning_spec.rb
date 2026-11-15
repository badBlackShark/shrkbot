# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::LiveWarning do
  include_context "component view context"

  subject(:warning) do
    Nokogiri::HTML5.fragment(
      described_class.new(fields: ["a[b]"], rule: "includes-any", list: ["1", "2"], shown:, class: "mt-3").render_in(view_context) { "Careful" }
    ).at_css("[data-controller=live-warning]")
  end

  let(:callout) { warning.at_css("[data-live-warning-target=callout]") }

  let(:shown) { true }

  it "wires the fields, rule and list to the controller" do
    expect(JSON.parse(warning["data-live-warning-fields-value"])).to eq(["a[b]"])
    expect(warning["data-live-warning-rule-value"]).to eq("includes-any")
    expect(JSON.parse(warning["data-live-warning-list-value"])).to eq(["1", "2"])
  end

  it "is a polite status region" do
    expect(warning["role"]).to eq("status")
    expect(warning.key?("hidden")).to be(false)
  end

  it "shows the callout when shown" do
    expect(callout.key?("hidden")).to be(false)
    expect(callout.text).to include("Careful")
  end

  context "when not shown" do
    let(:shown) { false }

    it "hides the callout inside the region, not the region" do
      expect(callout.key?("hidden")).to be(true)
      expect(warning.key?("hidden")).to be(false)
    end
  end
end
