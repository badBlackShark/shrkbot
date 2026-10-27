# frozen_string_literal: true

require "rails_helper"

RSpec.describe Feeds::Thumbnail do
  include ActiveSupport::Testing::TimeHelpers

  subject(:result) { described_class.for(watch) }

  let(:watch) { instance_double(Integrations::Watch, watcher: "Integrations::Steam::NewsWatcher", watcher_class:, external_id: "440") }
  let(:watcher_class) { class_double(Integrations::Steam::NewsWatcher) }
  let(:artwork_url) { "https://cdn.test/hero_capsule.jpg?t=1" }

  before do
    allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
    allow(watcher_class).to receive(:artwork_url).with("440").and_return(artwork_url)
    allow(Integrations::Http).to receive(:get_bytes).with(artwork_url).and_return("jpeg")
    allow(Feeds::SquareImage).to receive(:call).with("jpeg").and_return("webp")
  end

  it "returns the padded image" do
    expect(result).to eq("webp")
  end

  it "looks up and downloads once for repeated calls" do
    2.times { described_class.for(watch) }

    expect(watcher_class).to have_received(:artwork_url).once
    expect(Integrations::Http).to have_received(:get_bytes).once
  end

  context "when the watcher has no artwork" do
    let(:artwork_url) { nil }

    before do
      allow(Integrations::Http).to receive(:get_bytes)
    end

    it "is nil without downloading anything" do
      expect(result).to be_nil
      expect(Integrations::Http).not_to have_received(:get_bytes)
    end
  end

  context "when the download fails" do
    before do
      allow(Integrations::Http).to receive(:get_bytes).and_raise(Integrations::Unavailable)
    end

    it "is nil" do
      expect(result).to be_nil
    end

    it "does not look up again within the failure window" do
      2.times { described_class.for(watch) }

      expect(watcher_class).to have_received(:artwork_url).once
    end

    it "looks up again once the failure window is up" do
      described_class.for(watch)

      travel_to(11.minutes.from_now) do
        described_class.for(watch)
      end

      expect(watcher_class).to have_received(:artwork_url).twice
    end
  end

  context "when the image cannot be decoded" do
    before do
      allow(Feeds::SquareImage).to receive(:call).and_raise(Vips::Error)
    end

    it "is nil" do
      expect(result).to be_nil
    end
  end
end
