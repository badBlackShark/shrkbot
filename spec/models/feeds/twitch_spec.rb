# frozen_string_literal: true

require "rails_helper"

RSpec.describe Feeds::Twitch do
  let(:subscription) { create(:feed_subscription, :twitch) }

  describe ".role_id_for" do
    subject(:role_id) { described_class.role_id_for(subscription, "Integrations::Twitch::StreamStarted") }

    before { subscription.settings.update!(live_role_id: 4242) }

    it "is the live role in the subscription's settings" do
      expect(role_id).to eq(4242)
    end
  end

  describe ".accepts?" do
    subject(:accepted) { described_class.accepts?(subscription, instance_double(Integrations::Twitch::StreamStarted)) }

    it { is_expected.to be(true) }
  end
end
