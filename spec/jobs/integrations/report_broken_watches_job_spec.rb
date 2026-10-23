# frozen_string_literal: true

require "rails_helper"
require "discordrb"

RSpec.describe Integrations::ReportBrokenWatchesJob do
  subject(:perform) { described_class.perform_now }

  let(:rest_token) { "Bot test-token" }
  let!(:broken) do
    create(
      :integration_watch,
      name: "Team Fortress 2",
      external_id: "440",
      failing_since: 25.hours.ago,
      last_error: "api.steampowered.com responded 503"
    )
  end

  before do
    create(:feed_subscription, :active, watch: broken)
    allow(Bot::Config).to receive_messages(owner_id: "999", rest_token:)
    allow(Discordrb::API::User).to receive(:create_pm).with(rest_token, "999").and_return({id: 77}.to_json)
    allow(Bot::Discord::Components).to receive(:create_message)
  end

  it "DMs the owner the newly broken watches" do
    perform

    expect(Bot::Discord::Components).to have_received(:create_message).with(
      channel_id: 77,
      content: "Polling has failed for 24 hours - shrkbot keeps retrying every hour:\n" \
               "- Team Fortress 2 (440): api.steampowered.com responded 503",
      allowed_mentions: {parse: []}
    )
  end

  it "stamps the reported watches" do
    expect { perform }.to change { broken.reload.broken_reported_at }.from(nil)
  end

  it "stays silent on the second run" do
    perform
    perform

    expect(Bot::Discord::Components).to have_received(:create_message).once
  end

  context "with a watch that is failing but not yet broken" do
    before do
      create(:integration_watch, failing_since: 2.hours.ago)
    end

    it "is not listed" do
      perform

      expect(Bot::Discord::Components).to have_received(:create_message).with(
        hash_including(content: a_string_matching(/\A[^\n]*\n- Team Fortress 2 \(440\): [^\n]*\z/))
      )
    end
  end

  context "with more than 10 broken watches" do
    before do
      11.times do |index|
        watch = create(:integration_watch, name: "Game #{index}", failing_since: (24 + index).hours.ago - 1.hour, last_error: "boom")
        create(:feed_subscription, :active, watch:)
      end
    end

    it "lists ten and summarises the rest" do
      perform

      expect(Bot::Discord::Components).to have_received(:create_message).with(
        hash_including(content: a_string_matching(/\A(?:[^\n]*\n){11}- and 2 more\z/))
      )
    end

    it "stamps every broken watch, listed or not" do
      perform

      expect(Integrations::Watch.broken.unreported).to be_empty
    end
  end

  context "with a watch that broke again after an earlier report" do
    let!(:broken) do
      create(
        :integration_watch,
        name: "Team Fortress 2",
        external_id: "440",
        failing_since: 25.hours.ago,
        broken_reported_at: 10.days.ago,
        last_error: "api.steampowered.com responded 503"
      )
    end

    it "reports it again" do
      perform

      expect(Bot::Discord::Components).to have_received(:create_message).with(
        hash_including(content: a_string_including("Team Fortress 2 (440)"))
      )
    end
  end

  context "with a broken watch no active subscription wants" do
    before do
      create(:integration_watch, name: "Dota 2", failing_since: 30.hours.ago, last_error: "boom")
    end

    it "is not listed" do
      perform

      expect(Bot::Discord::Components).to have_received(:create_message).with(
        hash_including(content: a_string_matching(/\A[^\n]*\n- Team Fortress 2 \(440\): [^\n]*\z/))
      )
    end

    it "is not stamped" do
      perform

      expect(Integrations::Watch.broken.unreported.pluck(:name)).to eq(["Dota 2"])
    end
  end

  context "when nothing is broken" do
    let!(:broken) { create(:integration_watch, failing_since: 1.hour.ago) }

    it "sends no message" do
      perform

      expect(Bot::Discord::Components).not_to have_received(:create_message)
    end
  end
end
