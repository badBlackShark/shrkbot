# frozen_string_literal: true

require "rails_helper"

RSpec.describe Bot::Discord::Rest do
  subject(:get_json) { described_class.get_json("/users/999", authorization: "Bot t") { |json| json.fetch("id") } }

  let(:http) { instance_double(Net::HTTP) }
  let(:response) { instance_double(Net::HTTPResponse, code: "200", body: {"id" => "999"}.to_json) }
  let(:sent_requests) { [] }

  before do
    allow(http).to receive(:request) do |request|
      sent_requests << request
      response
    end
    allow(Net::HTTP).to receive(:start).and_yield(http).and_return(response)
  end

  it "returns what the block makes of the parsed body" do
    expect(get_json).to eq("999")
  end

  it "identifies itself the way Discord asks bots to" do
    get_json

    expect(sent_requests.first["User-Agent"]).to start_with("DiscordBot (#{ReleaseInfo::REPO_URL}, ")
  end

  it "gives up on a slow Discord after five seconds, since pages wait on it" do
    get_json

    expect(Net::HTTP).to have_received(:start).with("discord.com", 443, hash_including(read_timeout: 5))
  end

  it "sends the given authorization" do
    get_json

    expect(sent_requests.first["Authorization"]).to eq("Bot t")
  end

  [401, 403].each do |status|
    context "when Discord answers #{status}" do
      let(:response) { instance_double(Net::HTTPResponse, code: status.to_s, body: "") }

      it "raises Bot::Discord::Unauthorized" do
        expect { get_json }.to raise_error(Bot::Discord::Unauthorized)
      end
    end
  end

  context "when Discord rate-limits the request" do
    let(:response) { instance_double(Net::HTTPResponse, code: "429", body: "", to_hash: {}) }

    before do
      allow(response).to receive(:[]).with("Retry-After").and_return(nil)
    end

    it "raises Bot::Discord::RateLimited" do
      expect { get_json }.to raise_error(Bot::Discord::RateLimited)
    end
  end

  context "when Discord fails" do
    let(:response) { instance_double(Net::HTTPResponse, code: "500", body: "") }

    it "raises Bot::Discord::Error with the original error as cause" do
      expect { get_json }.to raise_error(Bot::Discord::Error) { |error| expect(error.cause).to be_a(Integrations::Unavailable) }
    end
  end

  context "without a released version" do
    before do
      allow(ReleaseInfo).to receive(:current).and_return(nil)
    end

    it "still sends a valid bot User-Agent" do
      get_json

      expect(sent_requests.first["User-Agent"]).to eq("DiscordBot (#{ReleaseInfo::REPO_URL}, 0)")
    end
  end
end
