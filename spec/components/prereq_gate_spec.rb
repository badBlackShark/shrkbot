# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::PrereqGate do
  subject(:html) do
    described_class.new(**options).call { "body-content" }
  end

  let(:options) do
    {
      title: "Logging required",
      message: "Set up Logging before enabling this.",
      cta_label: "Set up Logging",
      cta_href: "/servers/123/logging"
    }
  end

  it "renders the reason title and message" do
    expect(html).to include("Logging required").and include("Set up Logging before enabling this.")
  end

  it "renders a CTA linking to cta_href" do
    expect(html).to include("/servers/123/logging").and include("Set up Logging")
  end

  it "renders the CTA as a secondary button with a trailing arrow icon" do
    arrow_svg = PhosphorIcons::Icon.new("arrow-right", style: :regular, class: "size-4").to_svg
    expect(html).to include(arrow_svg)
  end

  it "renders the body content as inert" do
    expect(html).to include("body-content").and include("inert")
  end

  it "renders the body at reduced opacity" do
    expect(html).to include("opacity-45")
  end

  it "renders no enable button" do
    expect(html).not_to include("enable-gate#enable")
  end

  context "with a custom icon" do
    let(:options) do
      {
        title: "Shield required",
        message: "Enable Server Shield first.",
        cta_label: "Open Server Shield",
        cta_href: "/servers/123/moderation",
        icon: "shield"
      }
    end

    it "uses the specified icon" do
      shield_svg = PhosphorIcons::Icon.new("shield", style: :regular, class: "mx-auto block size-5 text-text-muted").to_svg
      expect(html).to include(shield_svg)
    end
  end
end
