# frozen_string_literal: true

require "rails_helper"

RSpec.describe Feeds::VolumeLookup do
  include ActiveSupport::Testing::TimeHelpers

  subject(:result) { described_class.call(watcher_class, "440") }

  let(:watcher_class) { class_double(Integrations::Steam::NewsWatcher, name: "Integrations::Steam::NewsWatcher") }
  let(:volume) { Integrations::Volume.new(counts: {}, sample_size: 20) }

  before do
    allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
    allow(watcher_class).to receive(:volume).with("440").and_return(volume)
  end

  it "returns the watcher's volume" do
    expect(result).to eq(volume)
  end

  it "asks the watcher once for repeated lookups" do
    2.times { described_class.call(watcher_class, "440") }

    expect(watcher_class).to have_received(:volume).once
  end

  context "when the watcher raises an integration error" do
    before { allow(watcher_class).to receive(:volume).with("440").and_raise(Integrations::RateLimited) }

    it "returns nil" do
      expect(result).to be_nil
    end

    it "does not ask the watcher again within the minute" do
      2.times { described_class.call(watcher_class, "440") }

      expect(watcher_class).to have_received(:volume).once
    end

    it "asks the watcher again once the minute is up" do
      described_class.call(watcher_class, "440")

      travel_to(61.seconds.from_now) do
        described_class.call(watcher_class, "440")
      end

      expect(watcher_class).to have_received(:volume).twice
    end
  end
end
