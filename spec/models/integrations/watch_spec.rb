# frozen_string_literal: true

require "rails_helper"

RSpec.describe Integrations::Watch do
  include ActiveSupport::Testing::TimeHelpers

  let(:now) { Time.utc(2026, 10, 23, 13, 0, 5) }
  let(:failing_since) { now - 30.hours }

  describe ".due" do
    subject(:due) { described_class.due }

    let!(:healthy) { create(:integration_watch) }
    let!(:failing_recently) { create(:integration_watch, failing_since: now - 1.hour, polled_at: now - 5.minutes) }
    let!(:broken) { create(:integration_watch, failing_since:, polled_at:) }

    before do
      travel_to(now)
    end

    context "when a broken watch was last polled late in the previous hour's last tick" do
      let(:polled_at) { Time.utc(2026, 10, 23, 12, 0, 40) }

      it "retries it on the first tick of the new hour, so retries never drift" do
        expect(due).to contain_exactly(healthy, failing_recently, broken)
      end
    end

    context "when a broken watch was already polled this hour" do
      let(:now) { Time.utc(2026, 10, 23, 13, 10, 5) }
      let(:polled_at) { Time.utc(2026, 10, 23, 13, 0, 20) }

      it "leaves it for the next hour" do
        expect(due).to contain_exactly(healthy, failing_recently)
      end
    end
  end

  describe ".broken" do
    subject(:broken) { described_class.broken }

    let!(:failing_recently) { create(:integration_watch, failing_since: 1.hour.ago) }
    let!(:failing_long) { create(:integration_watch, failing_since: 25.hours.ago) }

    it "includes only watches failing for more than 24 hours" do
      expect(broken).to contain_exactly(failing_long)
    end
  end

  describe ".unreported" do
    subject(:unreported) { described_class.unreported }

    let!(:watch) { create(:integration_watch, failing_since:, broken_reported_at:) }

    context "without a report stamp" do
      let(:broken_reported_at) { nil }

      it "includes the watch" do
        expect(unreported).to contain_exactly(watch)
      end
    end

    context "with a stamp after the failure began" do
      let(:broken_reported_at) { failing_since + 6.hours }

      it "excludes the watch" do
        expect(unreported).to be_empty
      end
    end

    context "with a stamp from an earlier failure streak" do
      let(:broken_reported_at) { failing_since - 3.days }

      it "includes the watch" do
        expect(unreported).to contain_exactly(watch)
      end
    end
  end

  describe "#watcher_class" do
    it "constantizes the stored class name" do
      expect(build(:integration_watch).watcher_class).to eq(Integrations::Steam::NewsWatcher)
    end
  end

  describe "uniqueness" do
    subject(:duplicate) { build(:integration_watch, watcher: existing.watcher, external_id: existing.external_id) }

    let!(:existing) { create(:integration_watch) }

    it "rejects the same external id for the same watcher" do
      expect(duplicate).not_to be_valid
    end

    context "with another watcher" do
      subject(:duplicate) { build(:integration_watch, watcher: "Integrations::Twitch::StreamWatcher", external_id: existing.external_id) }

      it "accepts the same external id" do
        expect(duplicate).to be_valid
      end
    end
  end

  describe "demand" do
    let!(:active_watch) { create(:integration_watch) }
    let!(:inactive_watch) { create(:integration_watch) }
    let!(:orphan_watch) { create(:integration_watch) }

    before do
      create(:feed_subscription, :active, watch: active_watch)
      create(:feed_subscription, watch: inactive_watch)
    end

    describe ".demanded" do
      it "includes only watches an active subscription points at" do
        expect(described_class.demanded).to contain_exactly(active_watch)
      end

      it "chains with other scopes" do
        expect(described_class.where(id: [inactive_watch.id, orphan_watch.id]).demanded).to be_empty
      end
    end

    describe ".referenced" do
      it "includes every watch any subscription points at, active or not" do
        expect(described_class.referenced).to contain_exactly(active_watch, inactive_watch)
      end
    end

    context "without a registered source" do
      before do
        allow(described_class).to receive(:demand_sources).and_return([])
      end

      it "demands and references nothing" do
        expect([described_class.demanded, described_class.referenced]).to all(be_empty)
      end
    end
  end

  describe ".demanded_by" do
    let(:source) { Class.new }

    after do
      described_class.demand_sources -= [source]
    end

    it "registers a source once" do
      2.times { described_class.demanded_by(source) }

      expect(described_class.demand_sources.count(source)).to eq(1)
    end

    it "is wired to feed subscriptions by the initializer" do
      expect(described_class.demand_sources).to include(Feeds::Subscription)
    end
  end
end
