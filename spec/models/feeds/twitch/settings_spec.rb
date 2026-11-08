# frozen_string_literal: true

require "rails_helper"

RSpec.describe Feeds::Twitch::Settings do
  subject(:settings) { subscription.settings }

  let(:subscription) { create(:feed_subscription, :twitch) }

  it "shows viewers by default" do
    expect(settings.show_viewers).to be(true)
  end

  it "marks the card ended with a VOD link by default" do
    expect(settings.live_end_mode).to eq("mark_ended_with_vod")
  end

  describe "live_end_mode" do
    before { settings.live_end_mode = "vanish" }

    it { is_expected.not_to be_valid }
  end

  describe "categories" do
    before { settings.categories = categories }

    context "with a well-formed entry" do
      let(:categories) { [{"id" => "A", "name" => "Alpha"}] }

      it { is_expected.to be_valid }
    end

    context "with a non-hash entry" do
      let(:categories) { ["A"] }

      it { is_expected.not_to be_valid }
    end

    context "with an entry without an id" do
      let(:categories) { [{"name" => "Alpha"}] }

      it { is_expected.not_to be_valid }
    end
  end

  describe "#accepts_category?" do
    subject(:accepted) { settings.accepts_category?(category_id) }

    let(:category_id) { "A" }

    before { settings.categories = categories }

    context "when no category is listed" do
      let(:categories) { [] }

      it { is_expected.to be(true) }

      context "with an unknown category" do
        let(:category_id) { nil }

        it { is_expected.to be(true) }
      end
    end

    context "when categories are listed" do
      let(:categories) { [{"id" => "A", "name" => "Alpha"}] }

      it { is_expected.to be(true) }

      context "with another category" do
        let(:category_id) { "B" }

        it { is_expected.to be(false) }
      end

      context "with an unknown category" do
        let(:category_id) { nil }

        it { is_expected.to be(false) }
      end
    end
  end

  describe "#role_id_for" do
    subject(:role_id) { settings.role_id_for(event_type) }

    before { settings.update!(live_role_id: 77, featured_clips_role_id: 88) }

    context "with a live event" do
      let(:event_type) { "Integrations::Twitch::StreamStarted" }

      it { is_expected.to eq(77) }
    end

    context "with a media event" do
      let(:event_type) { "Integrations::Twitch::FeaturedClipPublished" }

      it { is_expected.to eq(88) }
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
