# frozen_string_literal: true

require "rails_helper"

RSpec.describe Bot::Discord::MessageApi do
  let(:http) { instance_double(Net::HTTP) }
  let(:response) { instance_double(Net::HTTPResponse, code:, body:) }
  let(:code) { "200" }
  let(:body) { {"id" => "123456789"}.to_json }
  let(:requests) { [] }

  before do
    allow(Bot::Config).to receive(:rest_token).and_return("Bot test-token")
    allow(http).to receive(:request) do |net_request|
      requests << net_request
      response
    end
    allow(Net::HTTP).to receive(:start).and_yield(http).and_return(response)
  end

  describe ".create" do
    subject(:create) { described_class.create(channel_id: "111", body: {content: "hi"}) }

    it "returns the created message id" do
      expect(create).to eq("123456789")
    end

    it "sends the bot token in the Authorization header" do
      create
      expect(requests.last["Authorization"]).to eq("Bot test-token")
    end

    it "sends a JSON content type" do
      create
      expect(requests.last["Content-Type"]).to eq("application/json")
    end

    context "when Discord rejects the request with a permission error" do
      let(:code) { "403" }
      let(:body) { "" }

      it "raises Error with the status" do
        expect { create }.to raise_error(described_class::Error) do |error|
          expect(error.status).to eq(403)
        end
      end
    end
  end

  describe ".edit" do
    subject(:edit) { described_class.edit(channel_id: "111", message_id: "222", body: {content: "hi"}) }

    it "issues a PATCH to the message URL" do
      edit
      expect(requests.last).to be_a(Net::HTTP::Patch)
      expect(requests.last.path).to eq("/api/#{Bot::Config::API_VERSION}/channels/111/messages/222")
    end

    it "returns nil" do
      expect(edit).to be_nil
    end
  end

  describe ".delete" do
    subject(:delete) { described_class.delete(channel_id: "111", message_id: "222") }

    context "when Discord confirms the deletion" do
      let(:code) { "204" }
      let(:body) { "" }

      it "returns nil" do
        expect(delete).to be_nil
      end
    end

    context "when the message is already gone" do
      let(:code) { "404" }
      let(:body) { "" }

      it "returns nil without raising" do
        expect(delete).to be_nil
      end
    end
  end

  context "when Discord responds with a server error" do
    subject(:create) { described_class.create(channel_id: "111", body: {content: "hi"}) }

    let(:code) { "500" }
    let(:body) { "boom" }

    it "raises Error with the status" do
      expect { create }.to raise_error(described_class::Error) do |error|
        expect(error.status).to eq(500)
      end
    end
  end

  context "when the request times out" do
    subject(:create) { described_class.create(channel_id: "111", body: {content: "hi"}) }

    before do
      allow(Net::HTTP).to receive(:start).and_raise(Net::OpenTimeout)
    end

    it "raises Error" do
      expect { create }.to raise_error(described_class::Error)
    end
  end
end
