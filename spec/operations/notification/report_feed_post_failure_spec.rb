# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::Notification::ReportFeedPostFailure do
  subject(:result) { described_class.call(subscription:, event:) }

  let(:watch) { create(:integration_watch) }
  let(:subscription) { create(:feed_subscription, :active, watch:) }
  let(:server) { subscription.server_configuration }
  let(:event) { create(:steam_news_event, watch:) }
  let!(:channel) { create(:server_channel, server_configuration: server, discord_id: subscription.channel_id, name: "news") }

  before do
    create(:feed_subscribed_event, subscription:, event_type: "Integrations::Steam::PatchNotesPublished")
  end

  it "records the subscription, its source and the channel name" do
    expect(result.value.data).to eq(
      "plugin_key" => "steam",
      "name" => watch.name,
      "channel_name" => "news",
      "subscription_id" => subscription.id
    )
  end

  context "when the channel is not known" do
    let!(:channel) { nil }

    it "leaves the channel name empty" do
      expect(result.value.data["channel_name"]).to be_nil
    end
  end

  context "when an active report for the subscription exists" do
    before do
      create(:notification, server_configuration: server, kind: "feed_post_failed", data: {"subscription_id" => subscription.id})
    end

    it "adds nothing" do
      expect { result }.not_to change(Notification, :count)
    end

    context "when it was dismissed" do
      before do
        server.notifications.update_all(dismissed_at: Time.current)
      end

      it "reports again" do
        expect { result }.to change(Notification, :count).by(1)
      end
    end
  end

  context "when the active report belongs to another subscription" do
    before do
      create(:notification, server_configuration: server, kind: "feed_post_failed", data: {"subscription_id" => "fds_other"})
    end

    it "reports" do
      expect { result }.to change(Notification, :count).by(1)
    end
  end
end
