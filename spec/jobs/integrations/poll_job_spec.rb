# frozen_string_literal: true

require "rails_helper"

RSpec.describe Integrations::PollJob do
  subject(:perform) { described_class.perform_now(watch) }

  let(:watch) { create(:integration_watch) }
  let(:watcher) { instance_double(Integrations::Steam::NewsWatcher, observe: events) }
  let(:events) { [build(:steam_news_event, watch:, subject_key: "g1")] }

  before do
    allow(Integrations::Steam::NewsWatcher).to receive(:new).with(watch).and_return(watcher)
  end

  it "primes a never-polled watch from what the watcher observed" do
    perform

    expect(watch.reload.primed_at).to be_present
    expect(watch.seen_items.pluck(:external_id)).to eq(["g1"])
  end

  context "when the provider is unavailable" do
    before do
      allow(watcher).to receive(:observe).and_raise(Integrations::Unavailable, "api.steampowered.com responded 503")
    end

    it "records the failure on the watch instead of raising" do
      perform

      expect(watch.reload).to have_attributes(failing_since: be_present, last_error: "api.steampowered.com responded 503")
    end
  end

  context "when the watcher raises something that is not an integration error" do
    before do
      allow(watcher).to receive(:observe).and_raise(NoMethodError, "our bug")
    end

    it "lets it raise and records no failure" do
      expect { perform }.to raise_error(NoMethodError)
      expect(watch.reload.failing_since).to be_nil
    end
  end
end
