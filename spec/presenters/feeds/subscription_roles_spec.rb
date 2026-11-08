# frozen_string_literal: true

require "rails_helper"

RSpec.describe Feeds::SubscriptionRoles do
  subject(:roles) { described_class.new(subscription) }

  context "when a Twitch follow pings a role per type" do
    let(:subscription) { create(:feed_subscription, :twitch) }

    before do
      subscription.settings.update!(live_role_id: 1, highlights_role_id: 2)
      create(:feed_subscribed_event, subscription:, event_type: "Integrations::Twitch::StreamStarted")
      create(:feed_subscribed_event, subscription:, event_type: "Integrations::Twitch::HighlightPublished")
    end

    it "maps each followed type to its own role" do
      expect(roles).to have_attributes(shared?: false)
      expect(roles.for("Integrations::Twitch::HighlightPublished")).to eq(2)
    end
  end

  context "when every followed type pings the same role" do
    let(:subscription) { create(:feed_subscription) }

    before do
      subscription.settings.update!(role_id: 7)
      create(:feed_subscribed_event, subscription:, event_type: "Integrations::Steam::PatchNotesPublished")
    end

    it "is shared" do
      expect(roles).to have_attributes(shared?: true, shared: 7)
    end
  end

  context "when the subscription follows no type yet" do
    let(:subscription) { create(:feed_subscription, :twitch) }

    before do
      subscription.settings.update!(highlights_role_id: 1)
    end

    it "reads the roles of every type the source offers" do
      expect(roles.for("Integrations::Twitch::HighlightPublished")).to eq(1)
    end
  end
end
