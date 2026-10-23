# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::Integrations::Events::Dispatch do
  include ActiveSupport::Testing::TimeHelpers

  subject(:result) { described_class.call(events:) }

  let(:now) { Time.utc(2026, 10, 23, 12, 0, 0) }
  let(:handler) { Class.new(ApplicationJob) }
  let(:events) { [event] }
  let!(:event) { create(:steam_news_event) }
  let!(:untouched) { create(:steam_news_event) }

  before do
    travel_to(now)
    allow(Integrations::Bus).to receive(:handlers_for).and_return(handlers)
    allow(handler).to receive(:perform_later)
  end

  context "when a handler is subscribed" do
    let(:handlers) { [handler] }

    it "enqueues the handler with the event" do
      result

      expect(handler).to have_received(:perform_later).once.with(event)
    end

    it "stamps dispatched_at on the dispatched events only" do
      result

      expect(event.reload.dispatched_at).to eq(now)
      expect(untouched.reload.dispatched_at).to be_nil
    end
  end

  context "when no handler is subscribed" do
    let(:handlers) { [] }

    it "leaves the event unstamped so the sweeper still finds it" do
      result

      expect(event.reload.dispatched_at).to be_nil
    end
  end

  context "when only some events have a handler" do
    let(:events) { [event, untouched] }
    let(:handlers) { [] }

    before do
      allow(Integrations::Bus).to receive(:handlers_for).with(event).and_return([handler])
    end

    it "stamps just the handled one" do
      result

      expect(event.reload.dispatched_at).to eq(now)
      expect(untouched.reload.dispatched_at).to be_nil
    end
  end
end
