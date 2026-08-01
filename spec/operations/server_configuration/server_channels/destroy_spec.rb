# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::ServerConfiguration::ServerChannels::Destroy do
  subject(:result) { described_class.call(server_channel:) }

  let!(:server_channel) { create(:server_channel) }

  it "removes the row" do
    expect { result }.to change(ServerChannel, :count).by(-1)
  end

  it "returns a successful result" do
    expect(result).to be_success
  end

  context "with overwrites on the channel" do
    let!(:overwrite) { create(:channel_overwrite, server_channel:) }

    it "removes the channel's overwrites too" do
      expect { result }.to change(ChannelOverwrite, :count).by(-1)
    end
  end
end
