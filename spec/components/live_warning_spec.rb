# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::LiveWarning do
  include_context "component view context"

  subject(:warning) do
    Nokogiri::HTML5.fragment(
      described_class.new(fields: ["a[b]"], rule: "includes-any", list: ["1", "2"], shown:, class: "mt-3").render_in(view_context) { "Careful" }
    ).at_css("[data-controller=live-warning]")
  end

  let(:shown) { true }

  it "wires the fields, rule and list to the controller" do
    expect(JSON.parse(warning["data-live-warning-fields-value"])).to eq(["a[b]"])
    expect(warning["data-live-warning-rule-value"]).to eq("includes-any")
    expect(JSON.parse(warning["data-live-warning-list-value"])).to eq(["1", "2"])
  end

  it "is visible when shown" do
    expect(warning.key?("hidden")).to be(false)
  end

  context "when not shown" do
    let(:shown) { false }

    it "is hidden" do
      expect(warning.key?("hidden")).to be(true)
    end
  end
end
