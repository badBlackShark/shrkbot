# frozen_string_literal: true

require "rails_helper"

RSpec.describe Feeds::TwitchCategory do
  let(:server_configuration) { create(:server_configuration) }
  let(:subscription) { create(:feed_subscription, :twitch_category, :active, server_configuration:) }
  let(:category_id) { subscription.watch.external_id }
  let(:stream_watch) { create(:integration_watch, :twitch) }
  let(:event) { create(:twitch_stream_started_event, watch: stream_watch, category_id:, language: "en", login: "streamer") }
  let(:live) { "Integrations::Twitch::StreamStarted" }

  describe ".accepts?" do
    subject(:accepted) { described_class.accepts?(subscription, event) }

    it { is_expected.to be(true) }

    context "when the stream is in another category" do
      let(:event) { create(:twitch_stream_started_event, watch: stream_watch, category_id: "other") }

      it { is_expected.to be(false) }
    end

    context "when the filters reject the stream, so a posted card stays live" do
      before { subscription.settings.update!(languages: %w[de], excluded_channels: ["streamer"], min_viewers: 500) }

      it { is_expected.to be(true) }
    end
  end

  describe ".postable?" do
    subject(:postable) { described_class.postable?(subscription, event) }

    let(:event) { create(:twitch_stream_sampled_event, watch: stream_watch, category_id:, language: "en", login: "streamer", viewer_count: 100) }

    it { is_expected.to be(true) }

    context "when the stream's language is filtered out" do
      before { subscription.settings.update!(languages: %w[de]) }

      it { is_expected.to be(false) }
    end

    context "when the streamer is excluded" do
      before { subscription.settings.update!(excluded_channels: ["@Streamer"]) }

      it { is_expected.to be(false) }
    end

    context "when the stream is below the floor" do
      before { subscription.settings.update!(min_viewers: 101) }

      it { is_expected.to be(false) }
    end

    context "when the stream is at the floor" do
      before { subscription.settings.update!(min_viewers: 100) }

      it { is_expected.to be(true) }
    end

    describe "a direct follow of the same channel" do
      let(:direct_server) { server_configuration }
      let(:direct_types) { [live] }
      let(:direct_categories) { [] }
      let!(:direct) do
        create(:feed_subscription, :twitch, :active, server_configuration: direct_server, watch: stream_watch).tap do |sub|
          direct_types.each { |type| create(:feed_subscribed_event, subscription: sub, event_type: type) }
          sub.settings.update!(categories: direct_categories)
        end
      end

      context "when it demands Live and accepts the stream" do
        it { is_expected.to be(false) }
      end

      context "when it follows clips only" do
        let(:direct_types) { %w[Integrations::Twitch::ClipCreated] }

        it { is_expected.to be(true) }
      end

      context "when its category filter rejects the stream" do
        let(:direct_categories) { [{"id" => "elsewhere", "name" => "Elsewhere"}] }

        it { is_expected.to be(true) }
      end

      context "when it belongs to another server" do
        let(:direct_server) { create(:server_configuration) }

        it { is_expected.to be(true) }
      end
    end
  end

  describe ".subscriptions_for" do
    subject(:found) { described_class.subscriptions_for(event) }

    it "finds the follows of the stream's category" do
      expect(found).to contain_exactly(subscription)
    end

    context "when only another category is followed" do
      let(:event) { build(:twitch_stream_started_event, watch: stream_watch, category_id: "other") }

      it { is_expected.to be_empty }
    end
  end

  describe ".lookup_param" do
    it "looks categories up by the category param" do
      expect(described_class.lookup_param).to eq(:category)
    end
  end

  describe ".lookup_reference" do
    subject(:reference) { described_class.lookup_reference(value) }

    context "with a picked category" do
      let(:value) { Feeds::Twitch::CategoryValue.dump({"id" => "509658", "name" => "Just Chatting"}) }

      it { is_expected.to eq("509658") }
    end

    context "with anything that is not a picked category" do
      let(:value) { "509658" }

      it "passes it through for the watcher to judge" do
        expect(reference).to eq("509658")
      end
    end
  end

  describe ".settings_from" do
    subject(:attributes) { described_class.settings_from(ActionController::Parameters.new(params).permit(*described_class.settings_params)) }

    let(:params) { {min_viewers: "5", role_id: "9", languages: ["", "en"], excluded_channels: ["@A"], ignored: "x"} }

    it "keeps the settings and drops blank language picks" do
      expect(attributes).to eq(min_viewers: "5", role_id: "9", languages: ["en"], excluded_channels: ["@A"])
    end
  end

  describe ".announcement" do
    subject(:announcement) { described_class.announcement(event:, subscription:) }

    before { allow(Feeds::Twitch::LiveImage).to receive(:for).and_return(nil) }

    it { is_expected.to be_a(Feeds::Twitch::Announcement) }

    context "when the stream left the category" do
      let(:event) { create(:twitch_stream_updated_event, watch: stream_watch, category_id: "other") }

      it { is_expected.to be_a(Feeds::Twitch::SwitchedAnnouncement) }
    end
  end

  describe ".retract?" do
    let(:event) { create(:twitch_stream_updated_event, watch: stream_watch, category_id: "other") }

    it "deletes on leaving the category when the follow says so" do
      subscription.settings.update!(switched_away: "delete")

      expect(described_class.retract?(subscription, event)).to be(true)
    end
  end
end
