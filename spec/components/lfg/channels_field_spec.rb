# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Lfg::ChannelsField do
  subject(:html) { described_class.new(channels:, selected:).render_in(view_context) }

  let(:view_context) { ApplicationController.new.view_context }
  let(:channels) { [Components::TomSelect::Option.for(value: 111, label: "lfg")] }
  let(:selected) { [111] }

  it "renders a multiple channel select with the stored selection" do
    expect(html).to include("Allowed channels")
    expect(html).to include('name="lfg[allowed_channel_ids][]"')
    expect(html).to include("multiple")
  end

  context "when nothing is selected" do
    let(:selected) { [] }

    it "nudges the admin to scope the channels" do
      expect(html).to include("Consider scoping")
    end
  end

  context "when no channels have synced" do
    let(:channels) { [] }
    let(:selected) { [] }

    it "shows the none message" do
      expect(html).to include("No channels have synced")
    end
  end
end
