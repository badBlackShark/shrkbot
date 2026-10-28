# frozen_string_literal: true

require "rails_helper"

RSpec.describe Integrations::PollJob do
  subject(:perform) { described_class.perform_now("Integrations::Steam::NewsWatcher") }

  let!(:first) { create(:integration_watch) }
  let!(:second) { create(:integration_watch) }
  let(:watchers) do
    {
      first => instance_double(Integrations::Steam::NewsWatcher, observe: []),
      second => instance_double(Integrations::Steam::NewsWatcher, observe: [])
    }
  end

  before do
    allow(Integrations::Steam::NewsWatcher).to receive(:new) { |watch| watchers.fetch(watch) }
    [first, second].each { |watch| create(:feed_subscription, :active, watch:) }
  end

  context "with watches of another watcher and a broken watch already polled this hour" do
    let!(:other) { create(:integration_watch, watcher: "Integrations::Other::Watcher") }
    let!(:not_due) { create(:integration_watch, failing_since: 30.hours.ago, polled_at: polled_this_hour) }
    let(:polled_this_hour) { Time.current.beginning_of_hour + 1.second }

    before do
      [other, not_due].each { |watch| create(:feed_subscription, :active, watch:) }
    end

    it "polls every due watch of that watcher and nothing else" do
      perform

      expect(Integrations::Watch.where.not(polled_at: nil).where.not(id: not_due.id)).to contain_exactly(first, second)
      expect(Integrations::Watch.where(polled_at: nil)).to contain_exactly(other)
      expect(not_due.reload.polled_at).to eq(polled_this_hour)
    end
  end

  context "with a watch no active subscription wants" do
    let!(:undemanded) { create(:integration_watch) }

    before do
      create(:feed_subscription, watch: undemanded)
      watchers[undemanded] = instance_double(Integrations::Steam::NewsWatcher, observe: [])
    end

    it "does not poll it" do
      perform

      expect(undemanded.reload.polled_at).to be_nil
      expect(watchers.fetch(undemanded)).not_to have_received(:observe)
    end
  end

  context "when one watch's provider is unavailable" do
    before do
      allow(watchers.fetch(first)).to receive(:observe).and_raise(Integrations::Unavailable, "api.steampowered.com responded 503")
    end

    it "records the failure on that watch and still polls the other" do
      perform

      expect(first.reload).to have_attributes(failing_since: be_present, last_error: "Integrations::Unavailable: api.steampowered.com responded 503")
      expect(second.reload.polled_at).to be_present
    end
  end

  context "when a watcher raises something that is not an integration error" do
    before do
      allow(watchers.fetch(first)).to receive(:observe).and_raise(NoMethodError, "our bug")
    end

    it "records it as a failure without raising and still polls the other" do
      expect { perform }.not_to raise_error
      expect(first.reload.last_error).to start_with("NoMethodError: our bug")
      expect(second.reload.polled_at).to be_present
    end

    it "reports the bug to the owner once, naming the watch" do
      expect { perform }.to have_enqueued_job(Integrations::ReportPollBugsJob)
        .with(["Team Fortress 2 (#{first.external_id}): NoMethodError: our bug"])
        .once
    end

    context "when the watch was already failing with the same error class" do
      let!(:first) { create(:integration_watch, failing_since: 2.hours.ago, polled_at: 1.hour.ago, last_error: "NoMethodError: older") }

      it "does not report it again" do
        expect { perform }.not_to have_enqueued_job(Integrations::ReportPollBugsJob)
      end
    end

    context "when the watch was already failing with an outage" do
      let!(:first) { create(:integration_watch, failing_since: 2.hours.ago, polled_at: 1.hour.ago, last_error: "Integrations::Unavailable: 503") }

      it "reports the bug at once" do
        expect { perform }.to have_enqueued_job(Integrations::ReportPollBugsJob)
          .with(["Team Fortress 2 (#{first.external_id}): NoMethodError: our bug"])
          .once
      end
    end

    context "when the watch is deleted while its poll raises" do
      before do
        allow(watchers.fetch(first)).to receive(:observe) do
          Feeds::Subscription.where(watch_id: first.id).delete_all
          Integrations::Watch.find(first.id).destroy!
          raise NoMethodError, "gone"
        end
      end

      it "reports nothing and still polls the other" do
        expect { perform }.not_to have_enqueued_job(Integrations::ReportPollBugsJob)
        expect(second.reload.polled_at).to be_present
      end
    end
  end

  context "when the provider is unavailable on a fresh watch" do
    before do
      allow(watchers.fetch(first)).to receive(:observe).and_raise(Integrations::Unavailable, "503")
    end

    it "does not report a bug" do
      expect { perform }.not_to have_enqueued_job(Integrations::ReportPollBugsJob)
    end
  end

  context "when the provider rate limits every request" do
    before do
      watchers.each_value do |watcher|
        allow(watcher).to receive(:observe).and_raise(Integrations::RateLimited, "slow down")
      end
    end

    it "records the failure and stops the batch" do
      perform

      expect(Integrations::Watch.where.not(failing_since: nil).count).to eq(1)
      expect(Integrations::Steam::NewsWatcher).to have_received(:new).once
    end

    it "reports the rate limit to the owner at once" do
      expect { perform }.to have_enqueued_job(Integrations::ReportRateLimitJob)
        .with(a_string_matching(/\ATeam Fortress 2 \(\d+\)\z/), "slow down", nil)
        .once
    end

    context "when the watches were already rate limited" do
      let(:rate_limited) { {failing_since: 1.hour.ago, polled_at: 1.hour.ago, last_error: "Integrations::RateLimited: slow down"} }
      let!(:first) { create(:integration_watch, **rate_limited) }
      let!(:second) { create(:integration_watch, **rate_limited) }

      it "does not report it again" do
        expect { perform }.not_to have_enqueued_job(Integrations::ReportRateLimitJob)
      end
    end
  end

  describe "concurrency" do
    it "runs one job per watcher class and discards the rest" do
      expect(described_class).to have_attributes(concurrency_on_conflict: :discard, concurrency_duration: 1.hour)
      expect(described_class.new("A::Watcher").concurrency_key).not_to eq(described_class.new("B::Watcher").concurrency_key)
    end
  end
end
