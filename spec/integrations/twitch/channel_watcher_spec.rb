# frozen_string_literal: true

require "rails_helper"

RSpec.describe Integrations::Twitch::ChannelWatcher do
  let(:users) { instance_double(Integrations::Twitch::Users) }
  let(:user) { Integrations::Twitch::User.new(id: "141981764", login: "twitchdev", display_name: "TwitchDev", profile_image_url: "https://example.test/a.png") }
  let(:target) { Integrations::Target.new(external_id: "141981764", name: "TwitchDev", image_url: "https://example.test/a.png") }

  describe ".resolve" do
    subject(:resolved) { described_class.resolve("https://twitch.tv/TwitchDev", users:) }

    before do
      allow(users).to receive(:find_by_login).with("twitchdev").and_return(user)
    end

    it "looks the parsed login up and maps the user to a target" do
      expect(resolved).to eq(target)
    end
  end

  describe ".refresh" do
    subject(:refreshed) { described_class.refresh(["141981764"], users:) }

    before do
      allow(users).to receive(:for).with(["141981764"]).and_return([user])
    end

    it "maps each user to a target" do
      expect(refreshed).to eq([target])
    end
  end

  describe ".followed_for_live" do
    subject(:followed_for_live) { described_class.followed_for_live }

    let!(:following) { create(:feed_subscription, :twitch, :active).watch }
    let!(:idle) { create(:feed_subscription, :twitch, :active).watch }
    let!(:steam) { create(:feed_subscription, :active).watch }

    before do
      create(:feed_subscribed_event, subscription: Feeds::Subscription.find_by!(watch: following), event_type: "Integrations::Twitch::StreamStarted")
      create(:feed_subscribed_event, subscription: Feeds::Subscription.find_by!(watch: steam), event_type: "Integrations::Steam::PatchNotesPublished")
    end

    it "includes only Twitch watches an active subscription follows for Live" do
      expect(followed_for_live).to contain_exactly(following)
    end
  end

  describe ".live_checked" do
    subject(:live_checked) { described_class.live_checked }

    let!(:following) { create(:feed_subscription, :twitch, :active).watch }
    let!(:open_session) { create(:integration_watch, :twitch, state: {"session" => "s1"}) }
    let!(:ended) { create(:integration_watch, :twitch, state: {"login" => "ended"}) }

    before do
      create(:feed_subscribed_event, subscription: Feeds::Subscription.find_by!(watch: following), event_type: "Integrations::Twitch::StreamStarted")
    end

    it "includes Live followers and any watch whose session is still open, so a switched-off follow still sees its stream end" do
      expect(live_checked).to contain_exactly(following, open_session)
    end
  end
end
