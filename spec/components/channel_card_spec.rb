# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::ChannelCard do
  subject(:html) do
    described_class.new(
      name: "welcomes[channel_id]",
      channels:,
      selected:,
      label: "Channel",
      help: "Pick a channel."
    ).render_in(view_context)
  end

  let(:view_context) { ApplicationController.new.view_context }
  let(:channels) { [Components::TomSelect::Option.for(value: 111, label: "general")] }
  let(:selected) { nil }

  it "renders the label and help text" do
    expect(html).to include("Channel").and include("Pick a channel.")
  end

  it "renders the channel select when channels are present" do
    expect(html).to include("<select")
  end

  it "does not render a required marker by default" do
    expect(html).not_to include("text-danger")
  end

  context "when required: true" do
    subject(:html) do
      described_class.new(
        name: "welcomes[channel_id]",
        channels:,
        selected:,
        label: "Channel",
        help: "Pick a channel.",
        required: true
      ).render_in(view_context)
    end

    it "renders the required marker" do
      expect(html).to include("text-danger").and include("*")
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
        label: "Channel",
        help: "Pick a channel."
      ).render_in(view_context) { "trailing content" }
    end

    it "renders the block inside the card" do
      expect(html).to include("trailing content")
    end
  end

  context "with extra attrs" do
    subject(:html) do
      described_class.new(
        name: "welcomes[channel_id]",
        channels:,
        selected:,
        label: "Channel",
        help: "Pick a channel.",
        data: {controller: "my-controller"}
      ).render_in(view_context)
    end

    it "forwards extra attrs to the card element" do
      expect(html).to include('data-controller="my-controller"')
    end
  end
end
