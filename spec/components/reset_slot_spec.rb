# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::ResetSlot do
  include_context "component view context"

  subject(:slot) { Nokogiri::HTML5.fragment(html).at_css("span") }

  let(:hidden) { true }
  let(:html) do
    described_class.new(
      label: "Reset to default",
      hidden:,
      slot_data: {x_target: "winReset"},
      data: {action: "x#reset"}
    ).render_in(view_context)
  end

  it "carries the target and wraps the reset button" do
    expect(slot["data-x-target"]).to eq("winReset")
    expect(slot.at_css("button")["data-action"]).to eq("x#reset")
  end

  it "renders hidden when told" do
    expect(slot.key?("hidden")).to be(true)
  end

  context "when not hidden" do
    let(:hidden) { false }

    it "renders visible" do
      expect(slot.key?("hidden")).to be(false)
    end
  end
end
