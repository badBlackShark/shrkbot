# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Lfg::ChannelsCard do
  subject(:html) { described_class.new(channels:, selected:).render_in(view_context) }

  let(:view_context) { ApplicationController.new.view_context }

  context "when channels are available" do
    let(:channels) { [Components::TomSelect::Option.for(value: 111, label: "lfg")] }

    context "when a channel is selected" do
      let(:selected) { [111] }

      it "renders the channel select" do
        expect(html).to include("<select")
        expect(html).to include(">lfg<")
      end

      it "omits the nudge callout" do
        expect(html).not_to include("Consider scoping it to a few dedicated channels")
      end
    end

    context "when no channel is selected" do
      let(:selected) { [] }

      it "renders the nudge callout" do
        expect(html).to include("Consider scoping it to a few dedicated channels")
      end
    end
  end

  context "when no channels have synced" do
    let(:channels) { [] }
    let(:selected) { [] }

    it "renders the none message instead of a select" do
      expect(html).to include("No channels have synced yet")
      expect(html).not_to include("<select")
    end
  end
end
