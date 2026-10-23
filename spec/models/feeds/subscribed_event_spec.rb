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
end
