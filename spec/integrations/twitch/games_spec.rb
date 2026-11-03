# frozen_string_literal: true

require "rails_helper"

RSpec.describe Integrations::Twitch::Games do
  subject(:found) { games.find("27471") }

  let(:games) { described_class.new(client:) }
  let(:client) { instance_double(Integrations::Twitch::Client) }
  let(:response) { JSON.parse(Rails.root.join("spec/fixtures/integrations/twitch/games_minecraft.json").read) }

  before do
    allow(client).to receive(:get_json) { |*_args, **_kwargs, &block| block.call(response) }
  end

  it "asks for the game by id" do
    found

    expect(client).to have_received(:get_json).with("/games", params: {id: "27471"})
  end

  it "returns the game with its box art at a fixed size" do
    expect(found).to eq(
      Integrations::Twitch::Game.new(
        id: "27471",
        name: "Minecraft",
        box_art_url: "https://static-cdn.jtvnw.net/ttv-boxart/27471_IGDB-285x380.jpg"
      )
    )
  end

  context "when the id is unknown" do
    let(:response) { {"data" => []} }

    it "is nil" do
      expect(found).to be_nil
    end
  end
end
