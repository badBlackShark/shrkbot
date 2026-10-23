# frozen_string_literal: true

require "rails_helper"

RSpec.describe Integrations::Steam::AppReference do
  describe ".parse" do
    {
      "store URL" => ["https://store.steampowered.com/app/1145360/Hades/", 1145360],
      "community hub URL" => ["https://steamcommunity.com/app/440/discussions/", 440],
      "SteamDB URL" => ["https://steamdb.info/app/730/charts/", 730],
      "bare id with whitespace" => ["  570 \n", 570]
    }.each do |label, (input, app_id)|
      it "reads a #{label}" do
        expect(described_class.parse(input)).to eq(app_id)
      end
    end

    ["0", "hades", "https://store.steampowered.com/sub/123"].each do |input|
      it "rejects #{input.inspect} as NotFound" do
        expect { described_class.parse(input) }.to raise_error(Integrations::NotFound)
      end
    end
  end
end
