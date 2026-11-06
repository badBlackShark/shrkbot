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

  describe ".live_watches" do
    subject(:live_watches) { described_class.live_watches }

    let!(:following) { create(:feed_subscription, :twitch, :active).watch }
    let!(:idle) { create(:feed_subscription, :twitch, :active).watch }
    let!(:steam) { create(:feed_subscription, :active).watch }

    before do
      create(:feed_subscribed_event, subscription: Feeds::Subscription.find_by!(watch: following), event_type: "Integrations::Twitch::StreamStarted")
      create(:feed_subscribed_event, subscription: Feeds::Subscription.find_by!(watch: steam), event_type: "Integrations::Steam::PatchNotesPublished")
    end

    it "includes only Twitch watches an active subscription follows for Live" do
      expect(live_watches).to contain_exactly(following)
    end
  end

  describe ".preview_url" do
    subject(:preview_url) { described_class.preview_url("shrkbot_dev") }

    let(:url) { "https://static-cdn.jtvnw.net/previews-ttv/live_user_shrkbot_dev-1280x720.jpg" }

    before do
      allow(Integrations::Http).to receive(:head)
    end

    it "is the preview URL, checked with a HEAD that treats a redirect as not found" do
      expect(preview_url).to eq(url)
      expect(Integrations::Http).to have_received(:head).with(url, status_errors: {302 => Integrations::NotFound})
    end

    context "when the preview redirects to the placeholder" do
      before do
        allow(Integrations::Http).to receive(:head).and_raise(Integrations::NotFound)
      end

      it "is nil" do
        expect(preview_url).to be_nil
      end
    end

    context "when Twitch is unavailable" do
      before do
        allow(Integrations::Http).to receive(:head).and_raise(Integrations::Unavailable)
      end

      it "raises" do
        expect { preview_url }.to raise_error(Integrations::Unavailable)
      end
    end
  end

  describe ".box_art_url" do
    subject(:box_art_url) { described_class.box_art_url("27471", games:) }

    let(:games) { instance_double(Integrations::Twitch::Games) }
    let(:game) { Integrations::Twitch::Game.new(id: "27471", name: "Minecraft", box_art_url: "https://example.test/box.jpg") }

    before do
      allow(games).to receive(:find).with("27471").and_return(game)
    end

    it "is the game's box art" do
      expect(box_art_url).to eq("https://example.test/box.jpg")
    end

    context "when Twitch has no such game" do
      let(:game) { nil }

      it "is nil" do
        expect(box_art_url).to be_nil
      end
    end
  end

  describe ".vod_url" do
    subject(:vod_url) { described_class.vod_url("141981764", stream_ids, videos:) }

    let(:videos) { instance_double(Integrations::Twitch::Videos) }
    let(:stream_ids) { %w[s1 s2] }
    let(:blank_video) { Integrations::Twitch::Video.members.index_with(nil) }
    let(:archives) do
      %w[s2 s9 s1].map do |stream_id|
        Integrations::Twitch::Video.new(**blank_video, stream_id:, url: "https://www.twitch.tv/videos/v-#{stream_id}")
      end
    end

    before do
      allow(videos).to receive(:for_user).and_return(archives)
    end

    it "is the URL of the archive of the first stream id that has one" do
      expect(vod_url).to eq("https://www.twitch.tv/videos/v-s1")
    end

    it "asks for the channel's archives" do
      vod_url

      expect(videos).to have_received(:for_user).with("141981764", type: "archive", first: 20)
    end

    context "when no archive matches" do
      let(:stream_ids) { ["s7"] }

      it { is_expected.to be_nil }
    end
  end
end
