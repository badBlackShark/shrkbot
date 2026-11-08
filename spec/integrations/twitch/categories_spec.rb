# frozen_string_literal: true

require "rails_helper"

RSpec.describe Integrations::Twitch::Categories do
  subject(:found) { categories.search("mine") }

  let(:categories) { described_class.new(client:) }
  let(:client) { instance_double(Integrations::Twitch::Client) }
  let(:response) do
    {
      "data" => [
        {"id" => "27471", "name" => "Minecraft", "box_art_url" => "https://static-cdn.jtvnw.net/ttv-boxart/27471_IGDB-52x72.jpg"},
        {"id" => "1", "name" => "Minesweeper", "box_art_url" => "https://static-cdn.jtvnw.net/ttv-boxart/1-52x72.jpg"}
      ]
    }
  end

  before do
    allow(client).to receive(:get_json) { |*_args, **_kwargs, &block| block.call(response) }
  end

  it "asks Twitch for the first 20 categories matching the query" do
    found

    expect(client).to have_received(:get_json).with("/search/categories", params: {query: "mine", first: 20})
  end

  it "returns each match with its id, name and box art as Twitch sent them" do
    expect(found).to eq(
      [
        Integrations::Twitch::Game.new(id: "27471", name: "Minecraft", box_art_url: "https://static-cdn.jtvnw.net/ttv-boxart/27471_IGDB-52x72.jpg"),
        Integrations::Twitch::Game.new(id: "1", name: "Minesweeper", box_art_url: "https://static-cdn.jtvnw.net/ttv-boxart/1-52x72.jpg")
      ]
    )
  end

  context "when nothing matches" do
    let(:response) { {"data" => []} }

    it "is empty" do
      expect(found).to eq([])
    end
  end
end
