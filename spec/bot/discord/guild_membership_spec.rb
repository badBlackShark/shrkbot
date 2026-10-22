# frozen_string_literal: true

require "rails_helper"
require "discordrb"

RSpec.describe Bot::Discord::GuildMembership do
  let(:guild_id) { 123_456 }
  let(:user_id) { 789 }
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

  describe ".user_member?" do
    subject(:user_member?) { described_class.user_member?(guild_id, user_id) }

    context "when resolve_member succeeds" do
      before do
        allow(Discordrb::API::Server).to receive(:resolve_member)
      end

      it "returns true" do
        expect(user_member?).to be(true)
      end
    end

    context "when resolve_member raises UnknownMember" do
      before do
        allow(Discordrb::API::Server).to receive(:resolve_member).and_raise(
          Discordrb::Errors::UnknownMember.new("Unknown Member")
        )
      end

      it "returns false" do
        expect(user_member?).to be(false)
      end
    end

    context "when resolve_member raises UnknownUser" do
      before do
        allow(Discordrb::API::Server).to receive(:resolve_member).and_raise(
          Discordrb::Errors::UnknownUser.new("Unknown User")
        )
      end

      it "returns false" do
        expect(user_member?).to be(false)
      end
    end

    context "when resolve_member raises a non-Discord error" do
      before do
        allow(Discordrb::API::Server).to receive(:resolve_member).and_raise(RuntimeError, "network failure")
      end

      it "lets the error propagate" do
        expect { user_member? }.to raise_error(RuntimeError, "network failure")
      end
    end
  end
end
