# frozen_string_literal: true

require "rails_helper"

RSpec.describe Feeds::Twitch::CategorySearch do
  subject(:results) { described_class.call(query) }

  let(:query) { " Mine " }
  let(:categories) { instance_double(Integrations::Twitch::Categories) }
  let(:games) { [Integrations::Twitch::Game.new(id: "27471", name: "Minecraft", box_art_url: "https://example.test/box.jpg")] }

  before do
    allow(Integrations::Twitch::Categories).to receive(:new).and_return(categories)
    allow(categories).to receive(:search).and_return(games)
  end

  it "returns plain id and name hashes from the trimmed query" do
    expect(results).to eq([{"id" => "27471", "name" => "Minecraft"}])
    expect(categories).to have_received(:search).with("Mine")
  end

  context "with a query longer than the bound" do
    let(:query) { "a" * 150 }

    it "sends only the first 100 characters" do
      results

      expect(categories).to have_received(:search).with("a" * 100)
    end
  end

  context "with a blank query" do
    let(:query) { "  " }

    it "is empty and does not call Twitch" do
      expect(results).to eq([])
      expect(Integrations::Twitch::Categories).not_to have_received(:new)
    end
  end

  context "when Twitch fails" do
    before { allow(categories).to receive(:search).and_raise(Integrations::Unavailable) }

    it { is_expected.to be_nil }
  end
end
