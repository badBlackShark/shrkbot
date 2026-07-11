# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Moderation::StaffPingCard do
  include_context "component view context"

  subject(:html) { described_class.new(ping_staff:).render_in(view_context) }

  let(:ping_staff) { true }

  it "renders the ping toggle with the correct field name" do
    expect(html).to include('name="moderation[ping_staff]"')
  end

  it "renders the label and help text" do
    expect(html).to include("Ping staff on alerts")
    expect(html).to include("Mention the staff role")
  end

  context "when ping_staff is enabled" do
    it "renders the checkbox as checked" do
      expect(html).to match(/type="checkbox"[^>]*\bchecked\b/)
    end
  end

  context "when ping_staff is disabled" do
    let(:ping_staff) { false }

    it "renders the checkbox unchecked" do
      expect(html).not_to match(/type="checkbox"[^>]*\bchecked\b/)
    end
  end
end
