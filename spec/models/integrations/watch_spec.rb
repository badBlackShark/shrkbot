# frozen_string_literal: true

require "rails_helper"

RSpec.describe Integrations::Watch do
  let!(:healthy) { create(:integration_watch) }
  let!(:failing_recently) { create(:integration_watch, failing_since: 1.hour.ago, polled_at: 5.minutes.ago) }
  let!(:broken_just_polled) { create(:integration_watch, failing_since: 25.hours.ago, polled_at: 10.minutes.ago) }
  let!(:broken_due_for_retry) { create(:integration_watch, failing_since: 25.hours.ago, polled_at: 61.minutes.ago) }

  describe ".due" do
    subject(:due) { described_class.due }

    it "includes healthy and recently failing watches, and broken ones only once the retry interval passed" do
      expect(due).to contain_exactly(healthy, failing_recently, broken_due_for_retry)
    end
  end

  describe ".broken" do
    subject(:broken) { described_class.broken }

    it "includes only watches failing for more than 24 hours" do
      expect(broken).to contain_exactly(broken_just_polled, broken_due_for_retry)
    end
  end

  describe "#watcher_class" do
    it "constantizes the stored class name" do
      expect(healthy.watcher_class).to eq(Integrations::Steam::NewsWatcher)
    end
  end

  describe "uniqueness" do
    subject(:duplicate) { build(:integration_watch, watcher: healthy.watcher, external_id: healthy.external_id) }

    it "rejects the same external id for the same watcher" do
      expect(duplicate).not_to be_valid
    end

    context "with another watcher" do
      subject(:duplicate) { build(:integration_watch, watcher: "Integrations::Twitch::StreamWatcher", external_id: healthy.external_id) }

      it "accepts the same external id" do
        expect(duplicate).to be_valid
      end
    end
  end
end
