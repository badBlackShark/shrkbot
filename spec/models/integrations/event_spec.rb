# frozen_string_literal: true

require "rails_helper"

RSpec.describe Integrations::Event do
  include ActiveSupport::Testing::TimeHelpers

  let(:now) { Time.utc(2026, 10, 23, 12, 0, 0) }

  before do
    travel_to(now)
  end

  it "keeps the freshness window shorter than ledger retention, so an item whose seen row was pruned comes back stale" do
    expect(described_class::FRESHNESS_WINDOW).to be < Ops::Integrations::Prune::RETENTION
  end

  describe ".stranded" do
    subject(:stranded) { described_class.stranded }

    let!(:just_inside_window) { create(:steam_news_event, created_at: now - 48.hours + 1.second) }
    let!(:just_outside_window) { create(:steam_news_event, created_at: now - 48.hours - 1.second) }
    let!(:too_fresh) { create(:steam_news_event, created_at: now - 30.seconds) }
    let!(:dispatched) { create(:steam_news_event, created_at: now - 1.hour, dispatched_at: now - 50.minutes) }
    let!(:stranded_event) { create(:steam_news_event, created_at: now - 10.minutes) }

    it "holds undispatched events inside the freshness window and older than a minute" do
      expect(stranded).to contain_exactly(just_inside_window, stranded_event)
    end
  end
end
