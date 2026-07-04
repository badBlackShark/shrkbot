# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::ConfigPage do
  include_context "component view context"

  subject(:html) do
    described_class.new(
      icon: "bell",
      title: "Reminders",
      description: "Manage reminders.",
      dashboard_path: "/servers/1",
      url: "/servers/1/reminders",
      dashboard_label:
    ).render_in(view_context) { "" }
  end

  context "when dashboard_label is provided" do
    let(:dashboard_label) { "Dev Refuge" }

    it "shows the given label in the breadcrumb" do
      expect(html).to include("Dev Refuge")
    end
  end

  context "when dashboard_label is nil" do
    let(:dashboard_label) { nil }

    it "falls back to the generic dashboard label" do
      expect(html).to include("Dashboard")
    end
  end
end
