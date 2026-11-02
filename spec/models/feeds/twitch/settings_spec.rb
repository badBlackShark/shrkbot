# frozen_string_literal: true

require "rails_helper"

RSpec.describe Feeds::Twitch::Settings do
  subject(:settings) { subscription.settings }

  let(:subscription) { create(:feed_subscription, :twitch) }

  it "shows viewers by default" do
    expect(settings.show_viewers).to be(true)
  end

  describe "#role_id_for" do
    subject(:role_id) { settings.role_id_for(event_type) }

    before { settings.update!(live_role_id: 77) }

    context "with a live event" do
      let(:event_type) { "Integrations::Twitch::StreamStarted" }

      it { is_expected.to eq(77) }
    end

    context "with an unknown event type" do
      let(:event_type) { "Integrations::Twitch::Nonsense" }

      it "raises" do
        expect { role_id }.to raise_error(KeyError)
      end
    end
  end

  describe "uniqueness" do
    subject(:duplicate) { described_class.new(subscription:) }

    it { is_expected.not_to be_valid }
  end
end
