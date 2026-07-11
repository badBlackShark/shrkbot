# frozen_string_literal: true

require "rails_helper"

RSpec.describe Bot::Commands::Donate do
  subject(:execute) { described_class.new(event).execute }

  let(:event) { double("event", respond: nil) }

  it "responds with a branded container, ephemerally" do
    expect(event).to receive(:respond) do |components:, ephemeral:, has_components:|
      expect(ephemeral).to be(true)
      expect(has_components).to be(true)
      expect(components.first[:type]).to eq(Bot::Discord::Components::CONTAINER)
    end
    execute
  end

  describe "the message content" do
    subject(:message) do
      [described_class::COSTS, described_class::PLEDGE, described_class::LINKS, described_class::FOOTER].join("\n")
    end

    it { is_expected.to include("https://paypal.me/trueblackshark") }
    it { is_expected.to include("https://liberapay.com/badBlackShark") }
    it { is_expected.to include("10.60€") }
    it { is_expected.to include("4.99€") }
    it { is_expected.to include("17.37€") }
    it { is_expected.not_to match(/yahoo/i) }
  end
end
