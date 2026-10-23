# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::Integrations::Watches::PruneOrphans do
  subject(:result) { described_class.call }

  let!(:orphan) { create(:integration_watch) }
  let!(:referenced_inactive) { create(:integration_watch) }
  let!(:referenced_active) { create(:integration_watch) }

  before do
    create(:steam_news_event, watch: orphan)
    create(:integration_seen_item, watch: orphan)
    create(:feed_subscription, watch: referenced_inactive)
    create(:feed_subscription, :active, watch: referenced_active)
  end

  it "destroys an unreferenced watch with its events and seen items" do
    result

    expect(Integrations::Watch.exists?(orphan.id)).to be(false)
    expect(Integrations::Event.where(watch_id: orphan.id)).to be_empty
    expect(Integrations::SeenItem.where(watch_id: orphan.id)).to be_empty
  end

  it "keeps watches a subscription points at, active or not" do
    result

    expect(Integrations::Watch.all).to contain_exactly(referenced_inactive, referenced_active)
  end
end
