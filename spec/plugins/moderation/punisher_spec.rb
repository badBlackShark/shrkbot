# frozen_string_literal: true

require "rails_helper"

RSpec.describe Moderation::Punisher do
  subject(:call) { described_class.call(member:, server:, punishment:, timeout_seconds:, reason:) }

  let(:member) { double("member") }
  let(:server) { double("server") }
  let(:timeout_seconds) { 300 }
  let(:reason) { "spamming" }

  context "with punishment 'none'" do
    let(:punishment) { "none" }

    it "sends no messages to member or server" do
      expect(member).not_to receive(:communication_disabled_until=)
      expect(server).not_to receive(:kick)
      expect(server).not_to receive(:ban)
      call
    end
  end

  context "with punishment 'timeout'" do
    let(:punishment) { "timeout" }

    it "sets communication_disabled_until on the member" do
      expect(member).to receive(:communication_disabled_until=)
      call
    end
  end

  context "with punishment 'kick'" do
    let(:punishment) { "kick" }

    it "kicks the member from the server" do
      expect(server).to receive(:kick).with(member, "spamming")
      call
    end
  end

  context "with punishment 'ban'" do
    let(:punishment) { "ban" }

    it "bans the member with zero message seconds" do
      expect(server).to receive(:ban).with(member, message_seconds: 0, reason: "spamming")
      call
    end
  end

  context "when discordrb raises an error" do
    let(:punishment) { "kick" }

    it "rescues the error and does not re-raise" do
      allow(server).to receive(:kick).and_raise(RuntimeError, "forbidden")
      expect { call }.not_to raise_error
    end
  end
end
