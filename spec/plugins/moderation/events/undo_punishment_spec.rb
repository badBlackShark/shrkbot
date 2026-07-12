# frozen_string_literal: true

require "rails_helper"

RSpec.describe Moderation::UndoPunishment do
  subject(:handle) { described_class.new(event).handle }

  let(:guild_id) { 111 }
  let(:staff_role_id) { 333 }
  let(:actor_id) { 222 }
  let(:target_id) { 999 }

  let!(:config) { create(:server_configuration, discord_id: guild_id) }
  let!(:settings) { create(:moderation_settings, server_configuration: config, staff_role_id:) }

  let(:staff_role) { double("role", id: staff_role_id) }
  let(:member) { double("member", mention: "<@#{actor_id}>", roles: [staff_role], permission?: false) }
  let(:server) { double("server", id: guild_id, name: "Test Server") }
  let(:user) { double("user", id: actor_id) }
  let(:bot) { double("bot") }

  let(:event) do
    double(
      "event",
      custom_id: "mod:undo_punishment:#{target_id}:timeout",
      server:,
      user:,
      respond: nil,
      bot:
    )
  end

  before do
    allow(server).to receive(:member).with(actor_id).and_return(member)
    allow(Moderation::Unpunisher).to receive(:call)
  end

  context "when the member lacks the staff role and Manage Messages" do
    let(:member) { double("member", mention: "<@#{actor_id}>", roles: [], permission?: false) }

    it "rejects without calling Unpunisher" do
      handle

      expect(Moderation::Unpunisher).not_to have_received(:call)
      expect(event).to have_received(:respond).with(hash_including(ephemeral: true))
    end

    it "does not call update_message" do
      expect(event).not_to receive(:update_message)
      handle
    end
  end

  context "when the member holds the staff role" do
    context "when Unpunisher returns :reversed" do
      let(:target_user) { double("target_user") }

      before do
        allow(Moderation::Unpunisher).to receive(:call).and_return(:reversed)
        allow(bot).to receive(:user).with(target_id).and_return(target_user)
        allow(target_user).to receive(:pm)
      end

      it "unpunishes the target from the custom_id, not the acting moderator" do
        handle

        expect(Moderation::Unpunisher).to have_received(:call).with(
          server:,
          user_id: target_id,
          punishment: "timeout"
        )
      end

      it "sends an apology DM to the target user" do
        handle

        expect(bot).to have_received(:user).with(target_id)
        expect(target_user).to have_received(:pm).with(
          I18n.t("moderation.image_scanning.undo_punishment.apology", server: "Test Server")
        )
      end

      it "responds ephemerally with the reversed_timeout message naming the target" do
        handle

        expect(event).to have_received(:respond).with(
          content: I18n.t("moderation.image_scanning.undo_punishment.reversed_timeout", user: "<@#{target_id}>"),
          ephemeral: true
        )
      end

      it "does not call update_message" do
        expect(event).not_to receive(:update_message)
        handle
      end

      context "when the user is unreachable and the DM raises" do
        before { allow(target_user).to receive(:pm).and_raise(RuntimeError, "cannot send messages to this user") }

        it "swallows the failure and still confirms to the moderator" do
          expect { handle }.not_to raise_error
          expect(event).to have_received(:respond).with(hash_including(ephemeral: true))
        end
      end

      context "when the bot cannot resolve the user" do
        before { allow(bot).to receive(:user).with(target_id).and_return(nil) }

        it "skips the DM without raising and still confirms" do
          expect { handle }.not_to raise_error
          expect(event).to have_received(:respond).with(hash_including(ephemeral: true))
        end
      end
    end

    context "when Unpunisher returns :not_in_server" do
      before { allow(Moderation::Unpunisher).to receive(:call).and_return(:not_in_server) }

      it "responds ephemerally with not_in_server message and does not DM" do
        expect(bot).not_to receive(:user)
        handle

        expect(event).to have_received(:respond).with(
          content: I18n.t("moderation.image_scanning.undo_punishment.not_in_server"),
          ephemeral: true
        )
      end
    end

    context "when Unpunisher returns :failed" do
      before { allow(Moderation::Unpunisher).to receive(:call).and_return(:failed) }

      it "responds ephemerally with the error message and does not DM" do
        expect(bot).not_to receive(:user)
        handle

        expect(event).to have_received(:respond).with(
          content: I18n.t("moderation.image_scanning.undo_punishment.failed"),
          ephemeral: true
        )
      end
    end

    context "when Unpunisher returns :noop" do
      before { allow(Moderation::Unpunisher).to receive(:call).and_return(:noop) }

      it "responds ephemerally with the generic error message and does not DM" do
        expect(bot).not_to receive(:user)
        handle

        expect(event).to have_received(:respond).with(
          content: I18n.t("moderation.image_scanning.undo_punishment.failed"),
          ephemeral: true
        )
      end
    end
  end

  context "when the member lacks the staff role but has Manage Messages" do
    let(:member) { double("member", mention: "<@#{actor_id}>", roles: [], permission?: true) }

    before { allow(Moderation::Unpunisher).to receive(:call).and_return(:noop) }

    it "is authorized and calls Unpunisher" do
      handle
      expect(Moderation::Unpunisher).to have_received(:call)
    end
  end
end
