# frozen_string_literal: true

require "rails_helper"

RSpec.describe Moderation::MemberTimeoutLog do
  subject(:handle) { described_class.new(event).handle }

  let(:guild_id) { 111 }
  let(:user_id) { 222 }
  let(:timeout_until) { Time.at(1_700_000_000) }

  let(:user) do
    double(
      "user",
      id: user_id,
      communication_disabled?: true,
      communication_disabled_until: timeout_until
    )
  end
  let(:server) { double("server", id: guild_id) }
  let(:bot) { double("bot") }
  let(:event) { double("event", server:, user:, bot:) }

  let(:ledger) { double("ledger", first_sighting?: true) }
  let(:server_configuration) { double("server_configuration") }
  let(:attribution) { double("attribution", moderator: double("mod"), reason: "misbehaving") }
  let(:built_entry) { {title: "Member timed out", body: "body", meta: "meta"} }

  before do
    allow(Moderation::MemberLog::TimeoutLogLedger).to receive(:instance).and_return(ledger)
    allow(ServerConfiguration).to receive(:find_by).with(discord_id: guild_id).and_return(server_configuration)
    allow(Bot::ActivityLog).to receive(:enabled?).with(server_configuration, "moderation.member_timed_out").and_return(true)
    allow(Bot::ActivityLog).to receive(:post)
    allow(Moderation::MemberLog::AuditLogLookup).to receive(:attribution).and_return(attribution)
    allow(Moderation::MemberLog::ActivityEntry).to receive(:build).and_return(built_entry)
  end

  context "when no ServerConfiguration exists" do
    before { allow(ServerConfiguration).to receive(:find_by).and_return(nil) }

    it "does not post" do
      handle
      expect(Bot::ActivityLog).not_to have_received(:post)
    end
  end

  context "when action is disabled" do
    before { allow(Bot::ActivityLog).to receive(:enabled?).and_return(false) }

    it "does not post" do
      handle
      expect(Bot::ActivityLog).not_to have_received(:post)
    end

    it "does not call AuditLogLookup" do
      handle
      expect(Moderation::MemberLog::AuditLogLookup).not_to have_received(:attribution)
    end
  end

  context "when member is not communication_disabled" do
    let(:user) do
      double(
        "user",
        id: user_id,
        communication_disabled?: false,
        communication_disabled_until: nil
      )
    end

    it "does not post" do
      handle
      expect(Bot::ActivityLog).not_to have_received(:post)
    end

    it "does not call AuditLogLookup" do
      handle
      expect(Moderation::MemberLog::AuditLogLookup).not_to have_received(:attribution)
    end

    it "does not call the ledger" do
      handle
      expect(ledger).not_to have_received(:first_sighting?)
    end
  end

  context "when communication_disabled and attribution is present" do
    it "posts the built entry" do
      handle
      expect(Bot::ActivityLog).to have_received(:post).with(
        server_configuration,
        bot:,
        **built_entry
      )
    end
  end

  context "when communication_disabled but attribution is nil" do
    before { allow(Moderation::MemberLog::AuditLogLookup).to receive(:attribution).and_return(nil) }

    it "does not post" do
      handle
      expect(Bot::ActivityLog).not_to have_received(:post)
    end

    it "does not consume the ledger slot" do
      handle
      expect(ledger).not_to have_received(:first_sighting?)
    end
  end

  context "when the timeout was already logged" do
    before { allow(ledger).to receive(:first_sighting?).and_return(false) }

    it "does not post" do
      handle
      expect(Bot::ActivityLog).not_to have_received(:post)
    end
  end

  context "when the event has no member" do
    let(:event) { double("event", server:, user: nil, bot:) }

    it "does not post" do
      handle
      expect(Bot::ActivityLog).not_to have_received(:post)
    end
  end

  context "when filtering audit entries" do
    let(:matching_change) { double("change", new: "2026-07-11T00:00:00+00:00") }
    let(:matching_candidate) { double("candidate", changes: {"communication_disabled_until" => matching_change}) }
    let(:cleared_candidate) { double("candidate", changes: {"communication_disabled_until" => double("change", new: nil)}) }
    let(:role_candidate) { double("candidate", changes: nil) }
    let(:nick_candidate) { double("candidate", changes: {}) }

    before do
      allow(Moderation::MemberLog::AuditLogLookup).to receive(:attribution) do |*_args, **_kwargs, &block|
        [role_candidate, nick_candidate, cleared_candidate, matching_candidate].find(&block) && attribution
      end
    end

    it "accepts only entries that set communication_disabled_until" do
      handle
      expect(Bot::ActivityLog).to have_received(:post)
    end
  end
end
