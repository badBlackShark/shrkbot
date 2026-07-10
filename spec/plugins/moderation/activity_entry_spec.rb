# frozen_string_literal: true

require "rails_helper"

RSpec.describe Moderation::ActivityEntry do
  let(:target_mention) { "<@123>" }
  let(:target_username) { "targetuser" }
  let(:target) { double("target", mention: target_mention, username: target_username) }

  let(:moderator_mention) { "<@456>" }
  let(:moderator_username) { "moduser" }
  let(:moderator) { double("moderator", mention: moderator_mention, username: moderator_username) }

  let(:reason) { "rule violation" }

  context "ban entry" do
    subject(:result) { described_class.build(:member_banned, target:, moderator:, reason:) }

    it "has the correct title" do
      expect(result[:title]).to eq("Member banned")
    end

    it "includes the target in the body" do
      expect(result[:body]).to include(target_mention)
      expect(result[:body]).to include(target_username)
    end

    it "includes the moderator in the body" do
      expect(result[:body]).to include(moderator_mention)
      expect(result[:body]).to include(moderator_username)
    end

    it "includes the reason in the body" do
      expect(result[:body]).to include("Reason: rule violation")
    end

    it "has the correct meta" do
      expect(result[:meta]).to eq("From the Discord audit log")
    end
  end

  context "with nil moderator" do
    subject(:result) { described_class.build(:member_banned, target:, moderator: nil, reason:) }

    it "uses unknown moderator label in the body" do
      expect(result[:body]).to include("an unknown moderator")
    end
  end

  context "with nil reason" do
    subject(:result) { described_class.build(:member_banned, target:, moderator:, reason: nil) }

    it "uses no reason fallback in the body" do
      expect(result[:body]).to include("No reason was given.")
    end
  end

  context "with blank reason" do
    subject(:result) { described_class.build(:member_banned, target:, moderator:, reason: "") }

    it "uses no reason fallback in the body" do
      expect(result[:body]).to include("No reason was given.")
    end
  end

  context "timeout entry with timeout_until" do
    let(:timeout_until) { Time.at(1_700_000_000) }

    subject(:result) do
      described_class.build(:member_timed_out, target:, moderator:, reason:, timeout_until:)
    end

    it "includes the unix timestamp in discord format" do
      expect(result[:body]).to include("<t:1700000000:f>")
    end
  end
end
