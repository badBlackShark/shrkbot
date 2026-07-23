# frozen_string_literal: true

require "rails_helper"

RSpec.describe Lfg::Post do
  subject(:execute) { described_class.new(event).execute }

  let(:config) { create(:server_configuration, discord_id: 3) }
  let!(:settings) { config.create_lfg_settings!(cooldown_seconds: 300, post_lifetime_minutes: 360) }
  let!(:pingable_role) { settings.pingable_roles.create!(role_id: 55, required_role_ids: [], excluded_role_ids: []) }

  let(:options) { {"role" => "55", "message" => nil, "starting_in" => nil} }
  let(:member) { double("member", roles: [double("role", id: 7)], joined_at: Time.current) }
  let(:server) { double("server", id: 3, member: member) }
  let(:channel) { double("channel", id: 2, name: "c") }
  let(:user) { double("user", id: 1) }
  let(:interaction) { double("interaction", application_permissions: double("permissions", mention_everyone: true)) }
  let(:bot) { double("bot") }
  let(:event) do
    double("event", server:, channel:, user:, options:, interaction:, bot:, respond: nil, defer: nil, edit_response: nil)
  end
  let(:outcome) { Lfg::PostCreation::Outcome.new(ok: true, message: "🎮 Your LFG is up.") }

  before do
    allow(Lfg::PostCreation).to receive(:call).and_return(outcome)
  end

  context "when LFG is set up here" do
    it "calls Lfg::PostCreation with the event's data" do
      expect(Lfg::PostCreation).to receive(:call).with(
        hash_including(
          member: member,
          role_id: 55,
          channel: channel,
          mention_permission: true
        )
      ).and_return(outcome)
      execute
    end

    it "defers ephemerally before calling PostCreation" do
      expect(event).to receive(:defer).with(ephemeral: true)
      execute
    end

    it "edits the response with the outcome message and suppressed mentions" do
      expect(event).to receive(:edit_response).with(content: outcome.message, allowed_mentions: {parse: []})
      execute
    end

    context "when the bot's application permissions are absent from the payload" do
      let(:interaction) { double("interaction", application_permissions: nil) }

      it "passes a nil mention_permission" do
        expect(Lfg::PostCreation).to receive(:call)
          .with(hash_including(mention_permission: nil))
          .and_return(outcome)
        execute
      end
    end
  end

  describe "autocomplete" do
    subject(:autocomplete) { described_class.new(event).autocomplete }

    let!(:role_a) { create(:server_role, server_configuration: config, discord_id: 55, name: "Among Us") }
    let!(:role_b) { create(:server_role, server_configuration: config, discord_id: 56, name: "Apex Legends") }
    let!(:other_pingable) { settings.pingable_roles.create!(role_id: 56, required_role_ids: [], excluded_role_ids: []) }
    let(:options) { {"role" => "am"} }

    it "returns matching role names mapped to their id as a string" do
      expect(event).to receive(:respond).with(choices: {"Among Us" => "55"})
      autocomplete
    end

    context "with no input typed" do
      let(:options) { {"role" => ""} }

      it "returns every configured pingable role" do
        expect(event).to receive(:respond).with(choices: {"Among Us" => "55", "Apex Legends" => "56"})
        autocomplete
      end
    end

    context "when LFG isn't configured for this server" do
      let(:server) { double("server", id: 999_999, member: member) }

      it "returns no choices" do
        expect(event).to receive(:respond).with(choices: {})
        autocomplete
      end
    end

    context "with more than 25 matches" do
      let(:options) { {"role" => ""} }

      before do
        26.times do |n|
          role = create(:server_role, server_configuration: config, discord_id: 1_000 + n, name: "Game #{n}")
          settings.pingable_roles.create!(role_id: role.discord_id, required_role_ids: [], excluded_role_ids: [])
        end
      end

      it "caps the choices at 25" do
        expect(event).to receive(:respond) do |choices:|
          expect(choices.size).to eq(25)
        end
        autocomplete
      end
    end
  end

  describe "options" do
    it "declares role, message, and starting_in" do
      opts = double("options")
      allow(opts).to receive(:string)

      described_class.registration.options_block.call(opts)

      expect(opts).to have_received(:string).with("role", anything, hash_including(required: true, autocomplete: true))
      expect(opts).to have_received(:string).with("message", anything, hash_including(required: false))
      expect(opts).to have_received(:string).with("starting_in", anything, hash_including(required: false))
    end
  end
end
