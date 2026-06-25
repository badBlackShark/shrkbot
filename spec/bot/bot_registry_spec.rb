# frozen_string_literal: true

require "rails_helper"

RSpec.describe BotRegistry do
  after { described_class.register([]) }

  it "stores and returns the registered bots" do
    bots = [double("shard_one"), double("shard_two")]
    described_class.register(bots)
    expect(described_class.all).to eq(bots)
  end

  it "wraps a single bot in an array" do
    bot = double("bot")
    described_class.register(bot)
    expect(described_class.all).to eq([bot])
  end

  it "returns an empty array before anything is registered" do
    described_class.register(nil)
    expect(described_class.all).to eq([])
  end
end
