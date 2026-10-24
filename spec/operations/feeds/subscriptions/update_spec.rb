# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::Feeds::Subscriptions::Update do
  subject(:result) do
    described_class.call(
      subscription:,
      channel_id: "999",
      role_id: "",
      body_length: "full",
      event_types:
    )
  end

  let(:followed_since) { 3.days.ago.change(usec: 0) }
  let(:subscription) { create(:feed_subscription, channel_id: 555, role_id: 777) }
  let!(:patch_notes) do
    create(
      :feed_subscribed_event,
      subscription:,
      event_type: "Integrations::Steam::PatchNotesPublished",
      subscribed_since: followed_since,
      template: "custom {title}"
    )
  end
  let!(:articles) { create(:feed_subscribed_event, subscription:, event_type: "Integrations::Steam::ArticlePublished") }
  let(:event_types) { %w[Integrations::Steam::PatchNotesPublished Integrations::Steam::AnnouncementPublished] }

  it "updates channel, role and post length" do
    result

    expect(subscription.reload).to have_attributes(channel_id: 999, role_id: nil, body_length: "full")
  end

  it "keeps a followed type's follow time and template" do
    result

    expect(patch_notes.reload).to have_attributes(subscribed_since: followed_since, template: "custom {title}")
  end

  it "adds a newly checked type with a fresh follow time" do
    result

    added = subscription.subscribed_events.find_by!(event_type: "Integrations::Steam::AnnouncementPublished")
    expect(added.subscribed_since).to be_within(1.minute).of(Time.current)
  end

  it "removes an unchecked type" do
    result

    expect(subscription.subscribed_events.reload.map(&:event_type)).to match_array(event_types)
  end

  it "returns the subscription with its current events" do
    expect(result.value.subscribed_events.map(&:event_type)).to match_array(event_types)
  end

  context "when an event type is unknown" do
    let(:event_types) { %w[Nope] }

    it "fails and writes nothing" do
      expect(result).to be_failure

      expect(subscription.reload.channel_id).to eq(555)
      expect(subscription.subscribed_events.map(&:event_type)).to match_array(%w[Integrations::Steam::PatchNotesPublished Integrations::Steam::ArticlePublished])
    end
  end

  context "when the channel is blank" do
    subject(:result) do
      described_class.call(subscription:, channel_id: "", body_length: "full", event_types:)
    end

    it "fails and keeps the stored events" do
      expect(result).to be_failure

      expect(subscription.subscribed_events.count).to eq(2)
    end
  end
end
