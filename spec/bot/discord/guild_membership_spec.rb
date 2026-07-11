# frozen_string_literal: true

require "rails_helper"
require "discordrb"

RSpec.describe Bot::Discord::GuildMembership do
  let(:guild_id) { 123_456 }
  let(:rest_token) { "Bot token" }

  before do
    allow(Bot::Config).to receive(:rest_token).and_return(rest_token)
  end

  describe ".member?" do
    subject(:member?) { described_class.member?(guild_id) }

    context "when resolve succeeds" do
      before do
        allow(Discordrb::API::Server).to receive(:resolve)
      end

      it "returns true" do
        expect(member?).to be(true)
      end
    end

    context "when resolve raises UnknownServer" do
      before do
        allow(Discordrb::API::Server).to receive(:resolve).and_raise(
          Discordrb::Errors::UnknownServer.new("Unknown Server")
        )
      end

      it "returns false" do
        expect(member?).to be(false)
      end
    end

    context "when resolve raises NoPermission" do
      before do
        allow(Discordrb::API::Server).to receive(:resolve).and_raise(Discordrb::Errors::NoPermission)
      end

      it "returns false" do
        expect(member?).to be(false)
      end
    end

    context "when resolve raises a non-Discord error" do
      before do
        allow(Discordrb::API::Server).to receive(:resolve).and_raise(RuntimeError, "network failure")
      end

      it "lets the error propagate" do
        expect { member? }.to raise_error(RuntimeError, "network failure")
      end
    end
  end
end
