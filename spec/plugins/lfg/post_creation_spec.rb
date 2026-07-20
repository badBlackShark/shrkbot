# frozen_string_literal: true

require "rails_helper"

RSpec.describe Lfg::PostCreation do
  let(:config) { create(:server_configuration) }
  let!(:settings) { config.create_lfg_settings!(cooldown_seconds: 300, post_lifetime_minutes: 360) }
  let!(:pingable_role) { settings.pingable_roles.create!(role_id: 55, required_role_ids: [], excluded_role_ids: []) }

  let(:channel) { double("channel", id: 20, name: "lfg") }
  let(:bot) { double("bot") }
  let(:sent_message) { double("message", id: 500) }
  let(:cooldown_instance) { Lfg::Cooldown.new }
  let(:job_scheduler) { double("scheduler", perform_later: nil) }

  let(:actor_id) { 1 }
  let(:member_role_ids) { [] }
  let(:member_joined_at) { Time.current }
  let(:member) { double(id: actor_id, roles: member_role_ids.map { |id| double(id:) }, joined_at: member_joined_at) }
  let(:role_id) { 55 }
  let(:message) { nil }
  let(:starting_in) { nil }
  let(:mention_permission) { true }

  before do
    allow(Bot::Discord::Components).to receive(:send_to).and_return(sent_message)
    allow(Lfg::StartJob).to receive(:set).and_return(job_scheduler)
    allow(Lfg::ExpiryJob).to receive(:set).and_return(job_scheduler)
    allow(Bot::ActivityLog).to receive(:enabled?).and_return(false)
    allow(Lfg::Cooldown).to receive(:instance).and_return(cooldown_instance)
    allow(Ops::Lfg::Message::Post).to receive(:call)
  end

  def create_post
    described_class.call(
      server_configuration: config,
      channel:,
      bot:,
      member:,
      role_id:,
      message:,
      starting_in:,
      mention_permission:
    )
  end

  subject(:outcome) { create_post }

  context "immediate happy path (starting_in: nil)" do
    it "publishes and returns an ok outcome" do
      expect(outcome.ok?).to be(true)
    end

    it "confirms the post is up" do
      expect(outcome.message).to eq("Your Looking for Game post is up.")
    end

    it "sends with role-only allowed_mentions and a role-pinging subject" do
      outcome
      expect(Bot::Discord::Components).to have_received(:send_to).with(
        channel,
        anything,
        allowed_mentions: {parse: [], roles: [55]},
        subject: a_string_including("<@&55>")
      )
    end

    it "records the posted message" do
      outcome
      expect(Ops::Lfg::Message::Post).to have_received(:call).with(
        server_configuration: config,
        channel_id: 20,
        message_id: 500
      )
    end

    it "schedules the ExpiryJob but not the StartJob" do
      outcome
      expect(Lfg::ExpiryJob).to have_received(:set)
      expect(Lfg::StartJob).not_to have_received(:set)
    end

    it "starts the cooldown so an immediate second attempt is denied" do
      outcome
      second = create_post

      expect(second.ok?).to be(false)
      expect(second.message).to include(Lfg::Denial.reason_text(:cooldown, 300))
    end
  end

  context "scheduled happy path (starting_in: '2h')" do
    let(:starting_in) { "2h" }

    it "publishes and returns an ok outcome" do
      expect(outcome.ok?).to be(true)
    end

    it "schedules both the StartJob and the ExpiryJob" do
      outcome
      expect(Lfg::StartJob).to have_received(:set)
      expect(Lfg::ExpiryJob).to have_received(:set)
    end

    it "renders the post as not started" do
      expect(Lfg::PostMessage).to receive(:render).with(hash_including(started: false)).and_call_original
      outcome
    end
  end

  context "when the role isn't configured for LFG" do
    let(:role_id) { 999 }

    it "denies without publishing" do
      expect(outcome.ok?).to be(false)
      expect(outcome.message).to include(Lfg::Denial.reason_text(:role_not_configured))
    end

    it "never calls send_to" do
      outcome
      expect(Bot::Discord::Components).not_to have_received(:send_to)
    end

    it "never records a posted message" do
      outcome
      expect(Ops::Lfg::Message::Post).not_to have_received(:call)
    end

    context "when activity logging is enabled for lfg.denied" do
      before { allow(Bot::ActivityLog).to receive(:enabled?).and_return(true) }

      it "logs the denial" do
        expect(Bot::ActivityLog).to receive(:post)
        outcome
      end
    end

    context "when activity logging is disabled" do
      it "does not log" do
        expect(Bot::ActivityLog).not_to receive(:post)
        outcome
      end
    end
  end

  context "when shrkbot lacks the mention permission" do
    let(:mention_permission) { false }

    it "denies without publishing" do
      expect(outcome.ok?).to be(false)
      expect(outcome.message).to include(Lfg::Denial.reason_text(:no_permission))
    end

    it "never calls send_to" do
      outcome
      expect(Bot::Discord::Components).not_to have_received(:send_to)
    end

    it "never records a posted message" do
      outcome
      expect(Ops::Lfg::Message::Post).not_to have_received(:call)
    end
  end

  context "when starting_in is not a valid duration" do
    let(:starting_in) { "nope" }

    it "denies with a bad_duration message" do
      expect(outcome.ok?).to be(false)
      expect(outcome.message).to include(Lfg::Denial.reason_text(:bad_duration))
    end

    it "does not log the denial" do
      expect(Bot::ActivityLog).not_to receive(:post)
      outcome
    end

    it "never calls send_to" do
      outcome
      expect(Bot::Discord::Components).not_to have_received(:send_to)
    end

    it "never records a posted message" do
      outcome
      expect(Ops::Lfg::Message::Post).not_to have_received(:call)
    end
  end

  context "when the actor is on cooldown" do
    before do
      cooldown_instance.start(guild_id: config.discord_id, user_id: actor_id, at: Time.current, ttl: 300)
    end

    it "denies with a cooldown message" do
      expect(outcome.ok?).to be(false)
      expect(outcome.message).to include(Lfg::Denial.reason_text(:cooldown, 300))
    end

    it "never calls send_to and does not restart/extend the cooldown" do
      outcome
      expect(Bot::Discord::Components).not_to have_received(:send_to)
      expect(cooldown_instance.remaining(guild_id: config.discord_id, user_id: actor_id, at: Time.current)).to be <= 300
    end

    it "never records a posted message" do
      outcome
      expect(Ops::Lfg::Message::Post).not_to have_received(:call)
    end
  end
end
