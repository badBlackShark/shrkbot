# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::Integrations::Events::Record do
  subject(:result) { described_class.call(watch:, events:) }

  let(:watch) { create(:integration_watch) }
  let(:events) { [valid] }
  let(:valid) { build(:steam_news_event, watch:, subject_key: "valid", occurred_at: 1.hour.ago) }
  let(:invalid) { build(:steam_news_event, watch:, subject_key: "blank", occurred_at: 1.hour.ago, title: "") }

  it "saves the events and returns them" do
    expect(result.value).to eq([valid])
    expect(Integrations::Event.where(watch:).pluck(:subject_key)).to eq(["valid"])
  end

  it "dispatches the saved events to their handlers" do
    expect { result }.to have_enqueued_job(Feeds::AnnounceJob).once.with(valid)
  end

  it "stamps the dispatched events" do
    result

    expect(valid.reload.dispatched_at).to be_present
  end

  describe "locking" do
    let(:statements) { [] }
    let(:collector) do
      lambda do |*, payload|
        statements << payload[:sql]
      end
    end

    before do
      ActiveSupport::Notifications.subscribed(collector, "sql.active_record") do
        result
      end
    end

    it "locks the watch row before it checks for stored events, so a concurrent record of the same item waits and then skips it" do
      lock = statements.index { |sql| sql.match?(/FROM "integration_watches".*FOR UPDATE/m) }
      check = statements.index { |sql| sql.match?(/SELECT .* FROM "integration_events"/m) }

      expect(lock).to be < check
    end
  end

  context "when one event is invalid" do
    let(:events) { [valid, invalid] }

    it "drops it, publishes the rest and dispatches only those" do
      expect { result }.to have_enqueued_job(Feeds::AnnounceJob).once
      expect(result.value).to eq([valid])
      expect(Integrations::Event.where(watch:).pluck(:subject_key)).to eq(["valid"])
    end
  end

  context "when an event with the same type and subject is already stored" do
    before { create(:steam_news_event, watch:, subject_key: "valid", occurred_at: 2.hours.ago) }

    it "skips it instead of breaking on the unique index, and does not publish it" do
      expect(result.value).to eq([])
      expect(Integrations::Event.where(watch:).count).to eq(1)
    end
  end

  context "when another watch stored the same subject" do
    before { create(:steam_news_event, subject_key: "valid", occurred_at: 2.hours.ago) }

    it "still records it for this watch" do
      expect(result.value).to eq([valid])
    end
  end

  context "with no events" do
    let(:events) { [] }

    it "publishes and dispatches nothing" do
      expect { result }.not_to have_enqueued_job
      expect(result.value).to eq([])
    end
  end

  context "when dispatching fails" do
    before do
      allow(Ops::Integrations::Events::Dispatch).to receive(:call).and_raise("redis down")
    end

    it "still succeeds, leaving the events to the sweeper" do
      expect(result).to be_success
      expect(valid.reload.dispatched_at).to be_nil
    end
  end
end
