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

  it "sends the given authorization" do
    get_json

    expect(sent_requests.first["Authorization"]).to eq("Bot t")
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
