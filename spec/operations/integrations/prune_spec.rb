# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::Integrations::Prune do
  subject(:result) { described_class.call }

  let!(:old_event) { create(:steam_news_event, created_at: 15.days.ago) }
  let!(:recent_event) { create(:steam_news_event, created_at: 13.days.ago) }
  let!(:old_seen_item) { create(:integration_seen_item, created_at: 15.days.ago) }
  let!(:recent_seen_item) { create(:integration_seen_item, created_at: 13.days.ago) }

  it "deletes events and seen items older than 14 days" do
    result

    expect(Integrations::Event.exists?(old_event.id)).to be(false)
    expect(Integrations::SeenItem.exists?(old_seen_item.id)).to be(false)
  end

  it "keeps newer ones" do
    result

    expect(Integrations::Event.exists?(recent_event.id)).to be(true)
    expect(Integrations::SeenItem.exists?(recent_seen_item.id)).to be(true)
  end
end
