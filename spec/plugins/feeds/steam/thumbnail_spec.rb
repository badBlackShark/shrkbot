# frozen_string_literal: true

require "rails_helper"

RSpec.describe Feeds::Steam::Thumbnail do
  include ActiveSupport::Testing::TimeHelpers

  subject(:result) { described_class.for(watch) }

  let(:watch) { instance_double(Integrations::Watch, watcher: "Integrations::Steam::NewsWatcher", external_id: "440") }
  let(:store_items) { instance_double(Integrations::Steam::StoreItems) }
  let(:client) { instance_double(Integrations::Steam::Client) }
  let(:artwork_url) { "https://cdn.test/hero_capsule.jpg?t=1" }

  before do
    allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
    allow(Integrations::Steam::StoreItems).to receive(:new).and_return(store_items)
    allow(Integrations::Steam::Client).to receive(:new).and_return(client)
    allow(store_items).to receive(:hero_capsule_url).with("440").and_return(artwork_url)
    allow(client).to receive(:get_bytes).with(artwork_url).and_return("jpeg")
    allow(Feeds::SquareImage).to receive(:call).with("jpeg").and_return("webp")
  end

  it "returns the padded image" do
    expect(result).to eq("webp")
  end

  it "looks up and downloads once for repeated calls" do
    2.times { described_class.for(watch) }

    expect(store_items).to have_received(:hero_capsule_url).once
    expect(client).to have_received(:get_bytes).once
  end

  context "when the watcher has no artwork" do
    let(:artwork_url) { nil }

    it "is nil without downloading anything" do
      expect(result).to be_nil
      expect(client).not_to have_received(:get_bytes)
    end

    it "does not look up again within the day" do
      described_class.for(watch)

      travel_to(23.hours.from_now) do
        described_class.for(watch)
      end

      expect(store_items).to have_received(:hero_capsule_url).once
    end
  end

  context "when the lookup fails" do
    before do
      allow(store_items).to receive(:hero_capsule_url).and_raise(Integrations::Unavailable)
    end

    it "is nil" do
      expect(result).to be_nil
    end

    it "looks up again once the failure window is up" do
      described_class.for(watch)

      travel_to(11.minutes.from_now) do
        described_class.for(watch)
      end

      expect(store_items).to have_received(:hero_capsule_url).twice
    end
  end

  context "when the download fails" do
    before do
      allow(client).to receive(:get_bytes).and_raise(Integrations::Unavailable)
    end

    it "is nil" do
      expect(result).to be_nil
    end

    it "does not download again within the failure window" do
      2.times { described_class.for(watch) }

      expect(client).to have_received(:get_bytes).once
    end

    it "downloads again once the failure window is up, keeping the looked-up URL" do
      described_class.for(watch)

      travel_to(11.minutes.from_now) do
        described_class.for(watch)
      end

      expect(client).to have_received(:get_bytes).twice
      expect(store_items).to have_received(:hero_capsule_url).once
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
