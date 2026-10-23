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
    let!(:not_due) { create(:integration_watch, failing_since: 30.hours.ago, polled_at: Time.current) }

    before do
      [other, not_due].each { |watch| create(:feed_subscription, :active, watch:) }
    end

    it "polls every due watch of that watcher and nothing else" do
      perform

      expect(Integrations::Watch.where.not(primed_at: nil)).to contain_exactly(first, second)
      expect(Integrations::Watch.where(primed_at: nil)).to contain_exactly(other, not_due)
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

      expect(undemanded.reload.primed_at).to be_nil
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
      expect(second.reload.primed_at).to be_present
    end
  end

  context "when a watcher raises something that is not an integration error" do
    before do
      allow(watchers.fetch(first)).to receive(:observe).and_raise(NoMethodError, "our bug")
    end

    it "records it as a failure without raising and still polls the other" do
      expect { perform }.not_to raise_error
      expect(first.reload.last_error).to start_with("NoMethodError: our bug")
      expect(second.reload.primed_at).to be_present
    end

    it "reports the bug to the owner once, naming the watch" do
      expect { perform }.to have_enqueued_job(Integrations::ReportPollBugsJob)
        .with(["Team Fortress 2 (#{first.external_id}): NoMethodError: our bug"])
        .once
    end

    context "when the watch was already failing" do
      let!(:first) { create(:integration_watch, failing_since: 2.hours.ago) }

      it "does not report it again" do
        expect { perform }.not_to have_enqueued_job(Integrations::ReportPollBugsJob)
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

  context "when a watch is deleted while its batch runs" do
    before do
      allow(watchers.fetch(first)).to receive(:observe) do
        Feeds::Subscription.where(watch_id: first.id).delete_all
        Integrations::Watch.find(first.id).destroy!
        raise Integrations::Unavailable, "503"
      end
    end

    it "carries on with the next watch" do
      expect { perform }.not_to raise_error
      expect(Integrations::Watch.exists?(first.id)).to be(false)
      expect(second.reload.primed_at).to be_present
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
  end

  describe "concurrency" do
    it "runs one job per watcher class and discards the rest" do
      expect(described_class).to have_attributes(concurrency_on_conflict: :discard, concurrency_duration: 1.hour)
      expect(described_class.new("A::Watcher").concurrency_key).not_to eq(described_class.new("B::Watcher").concurrency_key)
    end
  end
end
