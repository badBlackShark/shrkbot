# frozen_string_literal: true

require "rails_helper"

RSpec.describe Discord::UserGuilds do
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
    expect(fetch).to contain_exactly(an_instance_of(Discord::Guild))
  end

  it "carries the parsed fields" do
    expect(fetch.first).to have_attributes(id: 42, name: "Dev Refuge", owner: true, permissions: 8, member_count: 2481)
  end

  context "when Discord rejects the access token" do
    let(:code) { "401" }
    let(:body) { "" }

    it "raises Unauthorized" do
      expect { fetch }.to raise_error(described_class::Unauthorized)
    end
  end

  context "when Discord responds with another error status" do
    let(:code) { "500" }
    let(:body) { "" }

    it "raises a generic error, not Unauthorized" do
      expect { fetch }.to raise_error(described_class::Error) do |error|
        expect(error).not_to be_a(described_class::Unauthorized)
      end
    end
  end

  context "when the body is not valid JSON" do
    let(:body) { "not json" }

    it "raises a wrapped error" do
      expect { fetch }.to raise_error(described_class::Error)
    end
  end
end
