# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::ChannelCard do
  subject(:html) do
    described_class.new(
      name: "welcomes[channel_id]",
      channels:,
      selected:,
      label: "Channel"
    ).render_in(view_context)
  end

  let(:view_context) { ApplicationController.new.view_context }
  let(:channels) { [Components::TomSelect::Option.for(value: 111, label: "general")] }
  let(:selected) { nil }

  it "renders the label" do
    expect(html).to include("Channel")
  end

  it "renders the channel select when channels are present" do
    expect(html).to include("<select")
  end

  it "does not render a required marker by default" do
    expect(html).not_to include("text-danger")
    expect(html).not_to include("aria-required")
  end

  context "when required: true" do
    subject(:html) do
      described_class.new(
        name: "welcomes[channel_id]",
        channels:,
        selected:,
        label: "Channel",
        required: true
      ).render_in(view_context)
    end

    it "renders the required marker" do
      expect(html).to include("text-danger").and include("*")
    end

    it "marks the select required" do
      expect(html).to include('aria-required="true"')
    end
  end

  context "when channels are empty" do
    let(:channels) { [] }

    it "renders the none message instead of a select" do
      expect(html).to include("No channels have synced yet")
      expect(html).not_to include("<select")
    end
  end

  context "with a block" do
    subject(:html) do
      described_class.new(
        name: "welcomes[channel_id]",
        channels:,
        selected:,
        label: "Channel"
      ).render_in(view_context) { "trailing content" }
    end

    it "renders the block inside the card" do
      expect(html).to include("trailing content")
    end
  end
end
