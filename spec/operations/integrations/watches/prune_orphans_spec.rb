# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::Integrations::Watches::PruneOrphans do
  subject(:result) { described_class.call }

  let!(:orphan) { create(:integration_watch) }
  let!(:referenced_inactive) { create(:integration_watch) }
  let!(:referenced_active) { create(:integration_watch) }
  let!(:with_events) { create(:integration_watch) }

  before do
    create(:steam_news_event, watch: with_events)
    create(:feed_subscription, watch: referenced_inactive)
    create(:feed_subscription, :active, watch: referenced_active)
  end

  it "destroys a watch nothing subscribes to and no event belongs to" do
    result

    expect(Integrations::Watch.exists?(orphan.id)).to be(false)
  end

  it "keeps watches a subscription points at, active or not, and watches that still have events" do
    result

    expect(Integrations::Watch.all).to contain_exactly(referenced_inactive, referenced_active, with_events)
  end

  context "when no demand source is registered" do
    include_context "without demand sources"

    it "deletes nothing, because an empty registry means the wiring failed, not that nothing is followed" do
      expect { result }.not_to change(Integrations::Watch, :count)
    end
  end
end
