# frozen_string_literal: true

require "rails_helper"

RSpec.describe Feeds::Steam do
  let(:subscription) { create(:feed_subscription) }

  describe ".role_id_for" do
    subject(:role_id) { described_class.role_id_for(subscription, "Integrations::Steam::PatchNotesPublished") }

    let(:subscription) { create(:steam_feed_subscription, role_id: 4242) }

    it "is the role in the subscription's settings" do
      expect(role_id).to eq(4242)
    end
  end

  describe ".accepts?" do
    subject(:accepted) { described_class.accepts?(subscription, event) }

    let(:subscription) { create(:steam_feed_subscription, languages: %w[de]) }
    let(:event) { instance_double(Integrations::Steam::NewsEvent, language:) }
    let(:language) { "de" }

    it { is_expected.to be(true) }

    context "when the event is in another language" do
      let(:language) { "ru" }

      it { is_expected.to be(false) }
    end
  end
end
