# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::ServerConfiguration::ServerChannel::Attributes do
  subject(:attributes) { described_class.call(channel) }

  let(:channel) do
    {discord_id: 111, name: "general", channel_type: 0, position: 2, parent_id: 999, overwrites: [{target_id: 555, target_type: "role", allow: 1024, deny: 2048}]}
  end

  it "maps the channel's fields to record attributes" do
    expect(attributes).to eq(name: "general", channel_type: 0, position: 2, parent_id: 999)
  end

  it "does not leak overwrites into the result" do
    expect(attributes).not_to have_key(:overwrites)
  end

  it "does not leak discord_id into the result" do
    expect(attributes).not_to have_key(:discord_id)
  end
end
