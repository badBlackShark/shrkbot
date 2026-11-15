# frozen_string_literal: true

require "rails_helper"

RSpec.describe Moderation::SetupSteps do
  subject(:steps) { described_class.new(config) }

  let(:config) { create(:server_configuration, discord_id: 900_000_001) }
  let(:logging_channel_id) { nil }

  before do
    config.create_logging_settings!(channel_id: logging_channel_id)
  end

  describe "#logging" do
    subject(:step) { steps.logging }

    context "when no log channel is set" do
      it "asks for a channel and links Logging" do
        expect(step.message).to eq(I18n.t("views.servers.moderation.sub_plugin_show.prerequisites.logging_channel.message"))
        expect(step.cta_href).to eq("/servers/900000001/logging")
      end
    end

    context "when a log channel is set" do
      let(:logging_channel_id) { 111 }

      it "asks to enable Logging and links Logging" do
        expect(step.message).to eq(I18n.t("views.servers.moderation.sub_plugin_show.prerequisites.logging_disabled.message"))
        expect(step.cta_href).to eq("/servers/900000001/logging")
      end
    end
  end

  describe "#staff_role" do
    it "links the Server Shield overview" do
      expect(steps.staff_role.cta_href).to eq("/servers/900000001/moderation")
    end
  end
end
