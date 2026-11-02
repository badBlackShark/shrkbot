# frozen_string_literal: true

require "rails_helper"

RSpec.describe Bot::Discord::OwnerUsername do
  subject(:lookup) { described_class.call }

  let(:http) { instance_double(Net::HTTP) }
  let(:response) { instance_double(Net::HTTPResponse, code:, body:) }
  let(:code) { "200" }
  let(:body) { {"id" => "999", "username" => "badblackshark"}.to_json }
  let(:owner_id) { "999" }

  before do
    allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
    allow(Bot::Config).to receive_messages(owner_id:, rest_token: "Bot t")
    allow(http).to receive(:request).and_return(response)
    allow(Net::HTTP).to receive(:start).and_yield(http).and_return(response)
  end

  it "returns the owner's username" do
    expect(lookup).to eq("badblackshark")
  end

  it "asks Discord for the owner with the bot token" do
    lookup

    expect(http).to have_received(:request).with(
      satisfy { |get| get.path == "/api/v10/users/999" && get["Authorization"] == "Bot t" }
    )
  end

  it "serves repeat lookups from the cache" do
    2.times { described_class.call }

    expect(Net::HTTP).to have_received(:start).once
  end

  context "when Discord responds with an error" do
    let(:code) { "500" }
    let(:body) { "" }

    it "returns nil" do
      expect(lookup).to be_nil
    end

    it "does not retry within the failure window" do
      2.times { described_class.call }

      expect(Net::HTTP).to have_received(:start).once
    end
  end

  context "when the request times out" do
    before do
      allow(Net::HTTP).to receive(:start).and_raise(Net::ReadTimeout)
    end

    it "returns nil" do
      expect(lookup).to be_nil
    end
  end

  context "without an owner id" do
    let(:owner_id) { nil }

    it "returns nil without calling Discord" do
      expect(lookup).to be_nil
      expect(Net::HTTP).not_to have_received(:start)
    end
  end
end
