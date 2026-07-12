# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Moderation::SpamProtectionForm do
  include_context "component view context"

  let(:config) { create(:server_configuration, discord_id: 900_000_001) }
  let(:settings) { create(:spam_protection_settings, server_configuration: config) }
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
    expect(html).to include('id="spam_protection-config"')
  end

  it "renders the channel threshold stepper with correct field name" do
    expect(html).to include('name="spam_protection[channel_threshold]"')
  end

  it "renders the window seconds stepper with correct field name" do
    expect(html).to include('name="spam_protection[window_seconds]"')
  end

  it "caps the threshold stepper at the server-side maximum for native validation" do
    expect(html).to include('max="500"')
  end

  it "caps the window seconds stepper at the server-side maximum for native validation" do
    expect(html).to include('max="60"')
  end

  it "renders the similarity range slider with correct field name" do
    expect(html).to include('name="spam_protection[similarity]"')
  end

  it "renders the symbol-only toggle with correct field name" do
    expect(html).to include('name="spam_protection[match_symbol_only_messages]"')
  end

  it "renders the action segmented control with correct field name" do
    expect(html).to include('name="spam_protection[action]"')
  end

  it "renders the purge and notify-only options" do
    expect(html).to include("Purge the messages")
    expect(html).to include("Notify only")
  end

  it "renders the punishment control with correct field name" do
    expect(html).to include('name="spam_protection[punishment]"')
  end

  it "renders the timeout_seconds duration select" do
    expect(html).to include('name="spam_protection[timeout_seconds]"')
  end

  it "renders the ban warning block" do
    expect(html).to include("A ban is permanent")
  end

  it "renders no enable_error callout by default" do
    expect(html).not_to include("A staff role is required.")
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
end
