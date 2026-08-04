# frozen_string_literal: true

RSpec.shared_context "audit log entry event" do
  let(:guild_id) { 111 }
  let(:moderator_id) { 555 }
  let(:bot_user_id) { 999 }

  let(:server) { double("server", id: guild_id) }
  let(:bot) { double("bot", profile: double("profile", id: bot_user_id)) }
  let(:moderator) { double("moderator", id: moderator_id) }
  let(:target) { double("target", id: 222) }
  let(:reason) { "spamming" }
  let(:changes) { {} }
  let(:audit_entry) { double("audit_entry", user: moderator, reason:, target:, changes:) }
  let(:event) { double("event", server:, bot:, entry: audit_entry, user_id: moderator_id) }

  let(:server_configuration) { double("server_configuration") }
end
