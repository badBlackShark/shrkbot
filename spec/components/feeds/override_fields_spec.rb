# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Feeds::OverrideFields do
  include_context "component view context"

  subject(:document) do
    Nokogiri::HTML.fragment(described_class.new(subscription:, event_type:, event:).render_in(view_context) { "MARKER" })
  end

  let(:subscription) { build(:feed_subscription) }
  let(:event_type) { "Integrations::Steam::PatchNotesPublished" }
  let(:event) { subscription.subscribed_events.build(event_type:, channel_id: 111) }
  let(:select) { document.at_css("select") }

  before do
    create(:server_channel, server_configuration: subscription.server_configuration, discord_id: 111, name: "clips")
  end

  it "renders the type's channel override, selected from the event" do
    expect(select["name"]).to eq("subscription[choices][#{event_type}][channel_id]")
    expect(select.at_css("option[selected]")["value"]).to eq("111")
    expect(document.text).to include("Channel override")
    expect(document.to_html).to include("Same as above")
  end

  it "puts a given block in a second cell of the same row" do
    row = document.at_css("div.flex-wrap")

    expect(row.element_children.map(&:text)).to include("MARKER")
    expect(row.element_children.first.at_css("select")).to be_present
  end
end
