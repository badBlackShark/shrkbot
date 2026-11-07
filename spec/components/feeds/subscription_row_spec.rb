# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Feeds::SubscriptionRow do
  include_context "component view context"

  subject(:text) do
    html = described_class.new(subscription:, plugin_key: :twitch, channel_label: "#clips", role_name: "Streams").render_in(view_context)
    Nokogiri::HTML5.fragment(html).text.squish
  end

  let(:failing_since) { 25.hours.ago }
  let(:watch) { create(:integration_watch, :twitch, failing_since:) }
  let(:subscription) { create(:feed_subscription, :twitch, watch:) }

  it "says Twitch has not answered for the channel's videos and clips, and that live posts still work" do
    expect(text).to include(
      "Twitch hasn't answered for this channel's videos and clips since",
      "UTC; live posts still work."
    )
  end
end
