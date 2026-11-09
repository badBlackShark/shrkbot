# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Feeds::TypeChannelField do
  include_context "component view context"

  subject(:select) do
    html = described_class.new(subscription:, event_type:, event:).render_in(view_context)
    Nokogiri::HTML5.fragment(html).at_css("select")
  end

  let(:server_configuration) { create(:server_configuration) }
  let(:subscription) { build(:feed_subscription, :twitch, server_configuration:) }
  let(:event_type) { "Integrations::Twitch::ClipCreated" }
  let(:channel_id) { 111 }
  let(:event) { subscription.subscribed_events.build(event_type:, channel_id:) }

  before do
    create(:server_channel, server_configuration:, discord_id: 111, name: "clips")
    create(:server_channel, discord_id: 222, name: "elsewhere")
  end

  it "names the select after the post type" do
    expect(select["name"]).to eq("subscription[channels][#{event_type}]")
  end

  it "offers a blank option and only this server's channels, with the stored one chosen" do
    expect(select.css("option").map { |option| option["value"] }).to eq(["", "111"])
    expect(select.at_css("option[selected]")["value"]).to eq("111")
  end

  context "without a channel of its own" do
    let(:channel_id) { nil }

    it "chooses nothing" do
      expect(select.css("option[selected]").map { |option| option["value"] }).to all(eq(""))
    end
  end

  context "without a followed event" do
    let(:event) { nil }

    it "chooses nothing" do
      expect(select.css("option[selected]").map { |option| option["value"] }).to all(eq(""))
    end
  end
end
