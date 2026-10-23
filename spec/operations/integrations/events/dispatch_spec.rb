# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::Integrations::Events::Dispatch do
  include ActiveSupport::Testing::TimeHelpers

  subject(:result) { described_class.call(events:) }

  let(:now) { Time.utc(2026, 10, 23, 12, 0, 0) }
  let(:handlers) { [Feeds::AnnounceJob] }
  let(:events) { [newest, oldest, middle] }
  let!(:newest) { create(:steam_news_event, occurred_at: now - 1.hour) }
  let!(:oldest) { create(:steam_news_event, occurred_at: now - 3.hours) }
  let!(:middle) { create(:steam_news_event, occurred_at: now - 2.hours) }
  let!(:untouched) { create(:steam_news_event, occurred_at: now - 4.hours) }

  before do
    travel_to(now)
    ActiveJob::Base.queue_adapter.enqueued_jobs.clear
    allow(Integrations::Bus).to receive(:handlers_for).and_return(handlers)
  end

  it "enqueues the handlers in occurred_at order, whatever order the events arrive in" do
    result

    enqueued = ActiveJob::Base.queue_adapter.enqueued_jobs.map { |job| job["arguments"].first["_aj_globalid"] }
    expect(enqueued).to eq([oldest, middle, newest].map { |event| event.to_global_id.to_s })
  end

  it "stamps dispatched_at on the dispatched events only" do
    result

    expect(Integrations::Event.where(dispatched_at: now)).to contain_exactly(newest, oldest, middle)
    expect(untouched.reload.dispatched_at).to be_nil
  end

  context "when no handler is subscribed" do
    let(:handlers) { [] }

    it "leaves the events unstamped so the sweeper still finds them" do
      result

      expect(Integrations::Event.undispatched).to contain_exactly(newest, oldest, middle, untouched)
    end
  end

  context "when only some events have a handler" do
    before do
      allow(Integrations::Bus).to receive(:handlers_for).with(oldest).and_return([])
    end

    it "stamps just the handled ones" do
      result

      expect(oldest.reload.dispatched_at).to be_nil
      expect(Integrations::Event.where(dispatched_at: now)).to contain_exactly(newest, middle)
    end
  end

  context "when enqueueing fails" do
    before do
      allow(ActiveJob).to receive(:perform_all_later).and_raise("redis down")
    end

    it "propagates and stamps nothing, so the sweeper redelivers the batch" do
      expect { result }.to raise_error("redis down")
      expect(Integrations::Event.undispatched.count).to eq(4)
    end
  end
end
