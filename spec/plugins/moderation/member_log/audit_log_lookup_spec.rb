# frozen_string_literal: true

require "rails_helper"
require "discordrb"

RSpec.describe Moderation::MemberLog::AuditLogLookup do
  subject(:result) { described_class.attribution(server, action: :member_ban_add, target_id: 42) }

  let(:target) { double("target", id: 42) }
  let(:user) { double("user") }
  let(:reason) { "spamming" }
  let(:creation_time) { Time.current - 5 }
  let(:entry) { double("entry", target:, user:, reason:, creation_time:) }
  let(:audit_logs) { double("audit_logs", entries: [entry]) }
  let(:server) { double("server", audit_logs:) }

  before do
    allow(server).to receive(:audit_logs).with(action: :member_ban_add, limit: 10).and_return(audit_logs)
  end

  context "with a matching recent entry" do
    it "returns an Attribution with the entry user and reason" do
      expect(result).to eq(described_class::Attribution.new(moderator: user, reason:))
    end
  end

  context "when entry target id does not match" do
    let(:target) { double("target", id: 99) }

    it "returns nil" do
      expect(result).to be_nil
    end
  end

  context "when the entry has no target" do
    let(:target) { nil }

    it "returns nil" do
      expect(result).to be_nil
    end
  end

  context "when entry is stale" do
    let(:creation_time) { Time.current - 120 }

    it "returns nil" do
      expect(result).to be_nil
    end
  end

  context "with a match block that rejects the candidate" do
    subject(:result) do
      described_class.attribution(server, action: :member_ban_add, target_id: 42) { |_| false }
    end

    it "returns nil" do
      expect(result).to be_nil
    end
  end

  context "with a match block that accepts the candidate" do
    subject(:result) do
      described_class.attribution(server, action: :member_ban_add, target_id: 42) { |_| true }
    end

    it "returns an Attribution" do
      expect(result).to eq(described_class::Attribution.new(moderator: user, reason:))
    end
  end

  context "when audit_logs raises Discordrb::Errors::NoPermission" do
    before do
      allow(server).to receive(:audit_logs).and_raise(Discordrb::Errors::NoPermission, "Insufficient permissions")
    end

    it "returns nil" do
      expect(result).to be_nil
    end
  end

  context "when audit_logs raises Discordrb::Errors::MissingPermissions" do
    before do
      allow(server).to receive(:audit_logs).and_raise(Discordrb::Errors::MissingPermissions.new("Missing Permissions"))
    end

    it "returns nil" do
      expect(result).to be_nil
    end
  end
end
