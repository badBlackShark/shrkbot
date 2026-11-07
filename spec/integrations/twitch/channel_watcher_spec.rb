# frozen_string_literal: true

require "rails_helper"

RSpec.describe Integrations::Twitch::ChannelWatcher do
  include ActiveSupport::Testing::TimeHelpers

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

  describe "#observe" do
    subject(:observe) { described_class.new(watch, videos:, clips:).observe }

    let(:videos) { instance_double(Integrations::Twitch::Videos, for_user: video_list) }
    let(:clips) { instance_double(Integrations::Twitch::Clips, for_broadcaster: clip_list) }
    let(:watch) { create(:integration_watch, :twitch, external_id: "141981764", polled_at:, failing_since:, demanded_types: wanted.to_set) }
    let(:wanted) { [] }
    let(:polled_at) { Time.utc(2026, 11, 6, 12, 0, 0) }
    let(:failing_since) { nil }
    let(:now) { Time.utc(2026, 11, 6, 12, 10, 0) }
    let(:blank_video) { Integrations::Twitch::Video.members.index_with(nil) }
    let(:blank_clip) { Integrations::Twitch::Clip.members.index_with(nil) }
    let(:published_at) { now - 3.hours }
    let(:thumbnail) { "https://static-cdn.jtvnw.net/cf_vods/x/thumb/thumb0-1280x720.jpg" }
    let(:video_list) do
      [
        video("1", "highlight"),
        video("2", "upload"),
        video("3", "archive"),
        video("4", "highlight", thumbnail_url: "https://vod-secure.twitch.tv/_404/404_processing_1280x720.png")
      ]
    end
    let(:clip_created_at) { now - 20.minutes }
    let(:clip_list) { [Integrations::Twitch::Clip.new(**blank_clip, id: "ClipOne-abc", broadcaster_name: "TwitchDev", creator_name: "Annonsu", title: "Ghost form", url: "https://www.twitch.tv/twitchdev/clip/ClipOne-abc", created_at: clip_created_at, thumbnail_url: "https://example.test/c.jpg", duration: 60, category_id: "18122")] }

    def video(id, type, thumbnail_url: thumbnail)
      Integrations::Twitch::Video.new(**blank_video, id:, type:, thumbnail_url:, user_login: "twitchdev", user_name: "TwitchDev", title: "Best rounds #{id}", url: "https://www.twitch.tv/videos/#{id}", published_at:, duration: 9360)
    end

    before do
      travel_to(now)
    end

    context "when no post type is wanted" do
      it "returns nothing and calls neither endpoint" do
        expect(observe).to eq([])
        expect(videos).not_to have_received(:for_user)
        expect(clips).not_to have_received(:for_broadcaster)
      end
    end

    context "when highlights are wanted" do
      let(:wanted) { ["Integrations::Twitch::HighlightPublished"] }

      it "builds only the finished highlights, keyed by video" do
        expect(observe).to contain_exactly(
          an_instance_of(Integrations::Twitch::HighlightPublished).and(
            have_attributes(
              subject_key: "video:1",
              story_key: "video:1",
              occurred_at: published_at,
              video_id: "1",
              login: "twitchdev",
              display_name: "TwitchDev",
              title: "Best rounds 1",
              url: "https://www.twitch.tv/videos/1",
              thumbnail_url: thumbnail,
              duration: 9360
            )
          )
        )
      end

      it "asks for the 20 most recent videos of every type and skips the clip endpoint" do
        observe

        expect(videos).to have_received(:for_user).with("141981764", type: "all", first: 20)
        expect(clips).not_to have_received(:for_broadcaster)
      end
    end

    context "when uploads are wanted" do
      let(:wanted) { ["Integrations::Twitch::UploadPublished"] }

      it "builds only the uploads" do
        expect(observe).to contain_exactly(
          an_instance_of(Integrations::Twitch::UploadPublished).and(have_attributes(subject_key: "video:2"))
        )
      end
    end

    context "when clips are wanted" do
      let(:wanted) { ["Integrations::Twitch::ClipCreated"] }

      it "builds the clips, keyed by clip" do
        expect(observe).to contain_exactly(
          an_instance_of(Integrations::Twitch::ClipCreated).and(
            have_attributes(
              subject_key: "clip:ClipOne-abc",
              story_key: "clip:ClipOne-abc",
              occurred_at: clip_created_at,
              clip_id: "ClipOne-abc",
              display_name: "TwitchDev",
              creator_name: "Annonsu",
              category_id: "18122",
              duration: 60
            )
          )
        )
      end

      it "fetches from ten minutes before the last poll, without a featured filter" do
        observe

        expect(clips).to have_received(:for_broadcaster).with("141981764", started_at: polled_at - 10.minutes, featured: nil)
        expect(videos).not_to have_received(:for_user)
      end

      context "when the watch has been failing" do
        let(:failing_since) { now - 30.minutes }
        let(:polled_at) { now - 5.minutes }

        it "fetches from before the first failure, so clips made between the last good poll and the failure are not skipped" do
          observe

          expect(clips).to have_received(:for_broadcaster).with("141981764", started_at: failing_since - 10.minutes, featured: nil)
        end
      end

      context "when the last poll is older than the freshness window" do
        let(:polled_at) { now - 3.days }

        it "fetches from 48 hours ago" do
          observe

          expect(clips).to have_received(:for_broadcaster).with("141981764", started_at: now - 48.hours, featured: nil)
        end
      end

      context "when the watch was never polled" do
        let(:polled_at) { nil }

        it "fetches from 48 hours ago" do
          observe

          expect(clips).to have_received(:for_broadcaster).with("141981764", started_at: now - 48.hours, featured: nil)
        end
      end
    end

    context "when featured clips are wanted" do
      let(:wanted) { ["Integrations::Twitch::FeaturedClipPublished"] }

      it "builds them under their own subject but the clip's story" do
        expect(observe).to contain_exactly(
          an_instance_of(Integrations::Twitch::FeaturedClipPublished).and(
            have_attributes(subject_key: "featured-clip:ClipOne-abc", story_key: "clip:ClipOne-abc")
          )
        )
      end

      it "fetches the featured clips of the last 48 hours" do
        observe

        expect(clips).to have_received(:for_broadcaster).with("141981764", started_at: now - 48.hours, featured: true)
      end
    end

    describe "the featured clip freshness ceiling" do
      let(:wanted) { ["Integrations::Twitch::FeaturedClipPublished"] }
      let(:clip_created_at) { now - 49.hours }

      it "posts no featured clip made more than 48 hours ago" do
        Ops::Integrations::Watches::RecordObservation.call(watch:, events: observe)

        expect(Integrations::Event.where(watch:)).to be_empty
      end
    end
  end
end
