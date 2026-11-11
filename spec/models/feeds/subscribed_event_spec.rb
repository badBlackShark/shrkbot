# frozen_string_literal: true

require "rails_helper"

RSpec.describe Feeds::SubscribedEvent do
  subject(:subscribed_event) { build(:feed_subscribed_event, subscription:, event_type:) }

  let(:subscription) { create(:feed_subscription) }
  let(:event_type) { "Integrations::Steam::PatchNotesPublished" }

  it { is_expected.to be_valid }

  context "without an event type" do
    let(:event_type) { nil }

    it { is_expected.not_to be_valid }
  end

  context "with an unknown event type" do
    let(:event_type) { "Integrations::Steam::Nonsense" }

    it { is_expected.not_to be_valid }
  end

  context "with another source's event type" do
    let(:event_type) { "Integrations::Steam::ArticlePublished" }

    before do
      allow(Feeds::Steam).to receive(:event_types).and_return(["Integrations::Steam::PatchNotesPublished"])
    end

    it { is_expected.not_to be_valid }
  end

  context "on a Twitch subscription" do
    let(:subscription) { create(:feed_subscription, :twitch) }
    let(:event_type) { "Integrations::Twitch::StreamStarted" }

    it { is_expected.to be_valid }

    it "is accepted by the database" do
      expect { subscribed_event.save! }.not_to raise_error
    end

    context "with a Steam event type" do
      let(:event_type) { "Integrations::Steam::PatchNotesPublished" }

      it { is_expected.not_to be_valid }
    end
  end

  it "starts following from now" do
    expect(subscribed_event.subscribed_since).to be_within(1.minute).of(Time.current)
  end

  context "without a follow time" do
    before do
      subscribed_event.subscribed_since = nil
    end

    it { is_expected.not_to be_valid }
  end

  context "when the subscription already has that event type" do
    before do
      create(:feed_subscribed_event, subscription:, event_type:)
    end

    it { is_expected.not_to be_valid }
  end

  context "when another subscription has that event type" do
    before do
      create(:feed_subscribed_event, event_type:)
    end

    it { is_expected.to be_valid }
  end

  describe "#apply" do
    subject(:apply) { subscribed_event.apply(**choices) }

    let(:choices) { {} }

    context "with custom text" do
      let(:choices) { {template: " Patch day: {title} ", notification: " Out now: {title} "} }

      it "keeps it stripped" do
        apply

        expect(subscribed_event).to have_attributes(template: "Patch day: {title}", notification_template: "Out now: {title}")
      end
    end

    context "with blank text" do
      let(:choices) { {template: "  ", notification: ""} }

      it "stores nothing" do
        apply

        expect(subscribed_event).to have_attributes(template: nil, notification_template: nil)
      end
    end

    context "with the default notification" do
      let(:choices) { {notification: subscription.source.default_notification(event_type)} }

      it "stores nothing" do
        apply

        expect(subscribed_event.notification_template).to be_nil
      end
    end

    context "with a blank channel" do
      let(:choices) { {channel_id: ""} }

      before { subscribed_event.channel_id = 5 }

      it "clears the channel" do
        apply

        expect(subscribed_event.channel_id).to be_nil
      end
    end

    context "with a channel" do
      let(:choices) { {channel_id: "777"} }

      it "keeps it" do
        apply

        expect(subscribed_event.channel_id).to eq(777)
      end
    end
  end
end
