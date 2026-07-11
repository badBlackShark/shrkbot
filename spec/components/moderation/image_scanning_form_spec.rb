# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Moderation::ImageScanningForm do
  include_context "component view context"

  let(:config) { create(:server_configuration, discord_id: 900_000_001) }
  let(:settings) { create(:image_scanning_settings, server_configuration: config) }
  let(:context) do
    instance_double(
      Moderation::SubPluginContext,
      settings:,
      plugin_enabled?: true,
      group_enabled?: true,
      staff_role_present?: true
    )
  end

  subject(:html) do
    described_class.new(
      context:
    ).render_in(view_context)
  end

  it "renders the wrapping div with the correct id" do
    expect(html).to include('id="image_scanning-config"')
  end

  it "renders the consent callout" do
    expect(html).to include("Before you turn this on")
  end

  it "renders the sensitivity radio card group with correct field name" do
    expect(html).to include('name="image_scanning[sensitivity]"')
  end

  it "renders all three sensitivity options" do
    expect(html).to include("Relaxed")
    expect(html).to include("Standard")
    expect(html).to include("Strict")
  end

  it "renders the custom keywords select with correct field name" do
    expect(html).to include('name="image_scanning[custom_keywords][]"')
  end

  it "wires the custom keywords select for free-tag creation" do
    expect(html).to include("tom-select-create-value")
  end

  it "renders the min_hits stepper with correct field name" do
    expect(html).to include('name="image_scanning[custom_keyword_min_hits]"')
  end

  it "renders the action segmented control with correct field name" do
    expect(html).to include('name="image_scanning[action]"')
  end

  it "renders Delete the image and Flag only options" do
    expect(html).to include("Delete the image")
    expect(html).to include("Flag only")
  end

  it "renders the punishment control with correct field name" do
    expect(html).to include('name="image_scanning[punishment]"')
  end

  it "renders the timeout_seconds duration select" do
    expect(html).to include('name="image_scanning[timeout_seconds]"')
  end

  it "renders the confirmed_punishment control with correct field name" do
    expect(html).to include('name="image_scanning[confirmed_punishment]"')
  end

  it "renders the confirmed_timeout_seconds duration select" do
    expect(html).to include('name="image_scanning[confirmed_timeout_seconds]"')
  end

  it "renders the image scanning explainer" do
    expect(html).to include("How image scanning works")
    expect(html).to include("Nothing is stored.")
  end

  it "renders the explainer with dropdown-menu class and menu target" do
    expect(html).to include("dropdown-menu")
    expect(html).to include('data-dropdown-target="menu"')
  end

  it "renders the report-as-scam hint" do
    expect(html).to include("Report as scam")
  end

  context "with an enable_error" do
    subject(:html) do
      described_class.new(
        context:,
        enable_error: "A staff role is required."
      ).render_in(view_context)
    end

    it "renders the error callout" do
      expect(html).to include("A staff role is required.")
    end
  end

  context "when the settings have custom keywords" do
    let(:settings) do
      create(
        :image_scanning_settings,
        server_configuration: config,
        custom_keywords: ["free nitro", "click link"]
      )
    end

    subject(:html) do
      described_class.new(
        context:
      ).render_in(view_context)
    end

    it "renders the keywords as option values in the select" do
      expect(html).to include("free nitro")
      expect(html).to include("click link")
    end

    it "caps the min_hits stepper at the keyword count" do
      expect(html).to include('name="image_scanning[custom_keyword_min_hits]"')
      expect(html).to include('max="2"')
    end
  end
end
