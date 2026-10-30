# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::Feeds::Subscriptions::Update do
  subject(:result) do
    described_class.call(
      subscription:,
      channel_id: "999",
      roles:,
      body_length: "full",
      languages:,
      event_types:,
      templates:
    )
  end

  let(:languages) { %w[de en] }
  let(:followed_since) { 3.days.ago.change(usec: 0) }
  let(:subscription) { create(:feed_subscription, channel_id: 555) }
  let!(:patch_notes) do
    create(
      :feed_subscribed_event,
      subscription:,
      event_type: "Integrations::Steam::PatchNotesPublished",
      subscribed_since: followed_since,
      template: "custom {title}",
      role_id: 777
    )
  end
  let!(:articles) { create(:feed_subscribed_event, subscription:, event_type: "Integrations::Steam::ArticlePublished") }
  let(:event_types) { %w[Integrations::Steam::PatchNotesPublished Integrations::Steam::AnnouncementPublished] }
  let(:templates) { {"Integrations::Steam::PatchNotesPublished" => "new {title}", "Integrations::Steam::AnnouncementPublished" => "fresh {game}"} }

  let(:roles) do
    {
      "Integrations::Steam::PatchNotesPublished" => "888",
      "Integrations::Steam::AnnouncementPublished" => "999"
    }
  end

  it "updates channel and post length" do
    result

    expect(subscription.reload).to have_attributes(channel_id: 999, body_length: "full")
  end

  it "updates the role of a kept type" do
    result

    expect(patch_notes.reload.role_id).to eq(888)
  end

  it "gives a newly followed type its role" do
    result

    expect(subscription.subscribed_events.find_by!(event_type: "Integrations::Steam::AnnouncementPublished").role_id).to eq(999)
  end

  context "with a blank role" do
    let(:roles) { {"Integrations::Steam::PatchNotesPublished" => ""} }

    it "clears the kept type's role" do
      result

      expect(patch_notes.reload.role_id).to be_nil
    end
  end

  it "stores the submitted languages" do
    result

    expect(subscription.reload.languages).to eq(%w[de en])
  end

  context "with no languages" do
    let(:subscription) { create(:feed_subscription, channel_id: 555, languages: %w[ru]) }
    let(:languages) { [] }

    it "clears the filter" do
      result

      expect(subscription.reload.languages).to eq([])
    end
  end

  it "keeps follow time and saves the submitted template" do
    result

    expect(patch_notes.reload).to have_attributes(subscribed_since: followed_since, template: "new {title}")
  end

  it "saves the template of a newly checked type" do
    result

    expect(subscription.subscribed_events.find_by!(event_type: "Integrations::Steam::AnnouncementPublished").template).to eq("fresh {game}")
  end

  context "with blank text" do
    let(:templates) { {"Integrations::Steam::PatchNotesPublished" => "  ", "Integrations::Steam::AnnouncementPublished" => ""} }

    it "stores no template" do
      result

      expect(subscription.subscribed_events.reload.map(&:template)).to all(be_nil)
    end
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
      described_class.call(subscription:, channel_id: "", roles:, body_length: "full", languages:, event_types:, templates:)
    end

    it "fails and keeps the stored events" do
      expect(result).to be_failure

      expect(subscription.subscribed_events.count).to eq(2)
    end
  end
end
