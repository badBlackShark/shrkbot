# frozen_string_literal: true

require "rails_helper"

RSpec.describe Integrations::Twitch::Channels do
  subject(:channels_for) { channels.for(ids) }

  let(:channels) { described_class.new(client:) }
  let(:client) { instance_double(Integrations::Twitch::Client) }
  let(:ids) { ["141981764"] }
  let(:response) { JSON.parse(Rails.root.join("spec/fixtures/integrations/twitch/channels_twitchdev.json").read) }

  before do
    allow(client).to receive(:get_json) { |*_args, **_kwargs, &block| block.call(response) }
  end

  it "asks for the broadcasters, repeating the key per id" do
    channels_for

    expect(client).to have_received(:get_json).with("/channels", params: {broadcaster_id: ["141981764"]})
  end

  it "returns the channels" do
    expect(channels_for).to eq(
      [
        Integrations::Twitch::Channel.new(
          broadcaster_id: "141981764",
          title: "Standard Output // October 16, 2024 at 2:30pm EDT",
          category_id: "1469308723",
          category_name: "Software and Game Development"
        )
      ]
    )
  end

  context "when the channel has no category" do
    let(:response) do
      super().tap do |body|
        body.fetch("data").first.merge!("game_id" => "", "game_name" => "")
      end
    end

    it "has no category" do
      expect(channels_for.first).to have_attributes(category_id: nil, category_name: nil)
    end
  end

  context "with more than 100 ids" do
    let(:ids) { (1..101).map(&:to_s) }

    it "asks in slices of 100" do
      channels_for

      expect(client).to have_received(:get_json).with("/channels", params: {broadcaster_id: ids.first(100)})
      expect(client).to have_received(:get_json).with("/channels", params: {broadcaster_id: ["101"]})
    end
  end

  context "without ids" do
    let(:ids) { [] }

    it "returns nothing and makes no request" do
      expect(channels_for).to eq([])
      expect(client).not_to have_received(:get_json)
    end
  end
end
