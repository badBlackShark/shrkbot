# frozen_string_literal: true

require "rails_helper"

RSpec.describe Bot::Discord::UserGuilds do
  subject(:fetch) { described_class.call("access-token") }

  let(:http) { instance_double(Net::HTTP) }
  let(:response) { instance_double(Net::HTTPResponse, code:, body:) }
  let(:code) { "200" }
  let(:body) { [{"id" => "42", "name" => "Dev Refuge", "owner" => true, "permissions" => "8", "icon" => nil, "approximate_member_count" => 2481}].to_json }

  before do
    allow(http).to receive(:request).and_return(response)
    allow(Net::HTTP).to receive(:start).and_yield(http).and_return(response)
  end

  it "maps the response into guilds" do
    expect(fetch).to contain_exactly(an_instance_of(Bot::Discord::Guild))
  end

  it "carries the parsed fields" do
    expect(fetch.first).to have_attributes(id: 42, name: "Dev Refuge", owner: true, permissions: 8, member_count: 2481)
  end

  it "asks the pinned Discord API version with the access token" do
    fetch

    expect(http).to have_received(:request).with(
      satisfy { |get| get.path == "/api/#{Bot::Config::API_VERSION}/users/@me/guilds?with_counts=true" && get["Authorization"] == "Bearer access-token" }
    )
  end

  [401, 403].each do |status|
    context "when Discord answers #{status}" do
      let(:code) { status.to_s }
      let(:body) { "" }

      it "raises Bot::Discord::Unauthorized" do
        expect { fetch }.to raise_error(Bot::Discord::Unauthorized)
      end
    end
  end

  context "when Discord rate-limits the token" do
    let(:code) { "429" }
    let(:body) { "" }

    before do
      allow(response).to receive_messages("[]": nil, to_hash: {})
    end

    it "raises Bot::Discord::RateLimited" do
      expect { fetch }.to raise_error(Bot::Discord::RateLimited)
    end
  end

  context "when Discord responds with a server error" do
    let(:code) { "500" }
    let(:body) { "" }

    it "raises Bot::Discord::Error" do
      expect { fetch }.to raise_error(Bot::Discord::Error)
    end
  end

  context "when the connection drops" do
    before do
      allow(Net::HTTP).to receive(:start).and_raise(Errno::ECONNRESET)
    end

    it "raises Bot::Discord::Error, which the controller turns into a friendly page" do
      expect { fetch }.to raise_error(Bot::Discord::Error)
    end
  end

  context "when the body is not valid JSON" do
    let(:body) { "not json" }

    it "raises Bot::Discord::Error" do
      expect { fetch }.to raise_error(Bot::Discord::Error)
    end
  end
end
