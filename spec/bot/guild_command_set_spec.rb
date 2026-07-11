# frozen_string_literal: true

require "rails_helper"
require "discordrb"

RSpec.describe GuildCommandSet do
  let(:server) { create(:server_configuration) }
  let(:discord_id) { server.discord_id }

  let(:moderation_plugin) { create(:plugin, key: "moderation", name: "Server Shield") }
  let(:image_scanning_plugin) { create(:plugin, key: "image_scanning", name: "Scam Image Detection") }

  def make_command(name:, plugin_key: nil, context: :guild)
    Class.new(BaseCommand) do
      command_name name
      description "test"
      register_in context
      plugin plugin_key if plugin_key
    end
  end

  let(:plugin_less_cmd) { make_command(name: :ping) }
  let(:image_scanning_cmd) { make_command(name: :report_scam, plugin_key: :image_scanning) }
  let(:global_cmd) { make_command(name: :info, context: :global) }

  describe "#payloads" do
    subject(:payloads) { described_class.new(discord_id, commands: commands).payloads }

    context "plugin-less guild command" do
      let(:commands) { [plugin_less_cmd] }

      it "is always included" do
        expect(payloads.map { |p| p[:name] }).to include(:ping)
      end
    end

    context "plugin command when activation is missing" do
      let(:commands) { [image_scanning_cmd] }

      it "is excluded" do
        expect(payloads).to be_empty
      end
    end

    context "plugin command when activation is disabled" do
      let(:commands) { [image_scanning_cmd] }

      before do
        create(:plugin_activation, server_configuration: server, plugin: image_scanning_plugin, enabled: false)
      end

      it "is excluded" do
        expect(payloads).to be_empty
      end
    end

    context "plugin command with the full moderation chain enabled" do
      let(:commands) { [image_scanning_cmd] }
      let(:logging_plugin) { create(:plugin, key: "logging", name: "Logging") }

      let(:moderation_activation) do
        PluginActivation.find_by!(server_configuration: server, plugin: moderation_plugin)
      end

      before do
        create(:logging_setting, server_configuration: server)
        create(:plugin_activation, server_configuration: server, plugin: logging_plugin, enabled: true)
        create(:moderation_settings, server_configuration: server, staff_role_id: 888)
        create(:plugin_activation, server_configuration: server, plugin: moderation_plugin, enabled: true)
        create(:plugin_activation, server_configuration: server, plugin: image_scanning_plugin, enabled: true)
      end

      it "is included" do
        expect(payloads.map { |p| p[:name] }).to include(:report_scam)
      end

      context "when the parent is later disabled" do
        before do
          moderation_activation.update!(enabled: false)
        end

        it "is excluded" do
          expect(payloads).to be_empty
        end
      end
    end

    context "plugin command whose key has no PluginCatalog definition" do
      let(:custom_plugin) { create(:plugin, key: "custom", name: "Custom") }
      let(:custom_cmd) { make_command(name: :custom, plugin_key: :custom) }
      let(:commands) { [custom_cmd] }

      before do
        create(:plugin_activation, server_configuration: server, plugin: custom_plugin, enabled: true)
      end

      it "is included when its activation is enabled" do
        expect(payloads.map { |p| p[:name] }).to include(:custom)
      end
    end

    context "when there is no ServerConfiguration row" do
      let(:discord_id) { 999_999_999 }
      let(:commands) { [plugin_less_cmd, image_scanning_cmd] }

      it "includes only plugin-less commands" do
        expect(payloads.map { |p| p[:name] }).to eq([:ping])
      end
    end

    context "owner-guild command" do
      let(:owner_guild_cmd) { make_command(name: :announce, context: :owner_guild) }
      let(:commands) { [owner_guild_cmd] }

      before do
        allow(BotConfig).to receive(:owner_guild_id).and_return(owner_guild_id)
      end

      context "in the owner's guild" do
        let(:owner_guild_id) { discord_id.to_s }

        it "is included" do
          expect(payloads.map { |p| p[:name] }).to include(:announce)
        end
      end

      context "in any other guild" do
        let(:owner_guild_id) { "123456" }

        it "is excluded" do
          expect(payloads).to be_empty
        end
      end

      context "when OWNER_GUILD_ID is not set" do
        let(:owner_guild_id) { nil }

        it "is excluded" do
          expect(payloads).to be_empty
        end
      end
    end

    context "global command in test environment (not development)" do
      let(:commands) { [global_cmd] }

      it "is excluded" do
        expect(payloads).to be_empty
      end
    end

    context "global command when Rails.env is development" do
      let(:commands) { [global_cmd] }

      before do
        allow(Rails.env).to receive(:development?).and_return(true)
      end

      it "is included" do
        expect(payloads.map { |p| p[:name] }).to include(:info)
      end
    end
  end
end
