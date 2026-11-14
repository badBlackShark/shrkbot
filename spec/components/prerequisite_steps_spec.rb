# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::PrerequisiteSteps do
  subject(:html) do
    described_class.new(**options).call
  end

  def icon_shape(name)
    PhosphorIcons::Icon.new(name, style: :regular).to_svg[/<path[^>]*>/]
  end

  let(:options) do
    {
      title: "Logging required",
      steps: [
        described_class::Step.new(
          message: "Set up Logging before enabling this.",
          cta_label: "Set up Logging",
          cta_href: "/servers/123/logging"
        )
      ]
    }
  end

  it "renders the reason title and message" do
    expect(html).to include("Logging required").and include("Set up Logging before enabling this.")
  end

  it "renders a CTA linking to cta_href" do
    expect(html).to include("/servers/123/logging").and include("Set up Logging")
  end

  context "with two steps" do
    let(:options) do
      {
        title: "Before you enable it",
        steps: [
          described_class::Step.new(message: "Turn Logging on.", cta_label: "Open Logging", cta_href: "/servers/123/logging"),
          described_class::Step.new(message: "Pick a staff role.", cta_label: "Open Server Shield", cta_href: "/servers/123/moderation")
        ]
      }
    end

    it "renders one call to action per step" do
      expect(html.scan(%r{href="/servers/123/(logging|moderation)"}).flatten).to eq(%w[logging moderation])
    end
  end

  it "renders the CTA as a secondary button with a trailing arrow icon" do
    expect(html).to include(icon_shape("arrow-right"))
  end

  context "with a custom icon" do
    let(:options) do
      {
        title: "Shield required",
        steps: [described_class::Step.new(message: "Enable Server Shield first.", cta_label: "Open Server Shield", cta_href: "/servers/123/moderation")],
        icon: "shield"
      }
    end

    it "uses the specified icon instead of the default" do
      expect(html).to include(icon_shape("shield"))
      expect(html).not_to include(icon_shape("lock"))
    end
  end
end
