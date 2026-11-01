# frozen_string_literal: true

require "rails_helper"

RSpec.describe Integrations::RefreshWatchesJob do
  subject(:perform) { described_class.perform_now("Integrations::Steam::NewsWatcher") }

  let!(:watch) { create(:integration_watch, external_id: "1145360", name: "Old") }
  let!(:other) { create(:integration_watch, watcher: "Integrations::Other::Watcher") }
  let!(:unreferenced) { create(:integration_watch, external_id: "570") }
  let(:targets) { [Integrations::Target.new(external_id: "1145360", name: "Hades", image_url: nil)] }
  let(:followed) { [watch, other] }

  before do
    followed.each { |followed_watch| create(:feed_subscription, watch: followed_watch) }
    allow(Integrations::Steam::NewsWatcher).to receive(:refresh).and_return(targets)
  end

  it "asks the watcher about its referenced watches only" do
    perform

    expect(Integrations::Steam::NewsWatcher).to have_received(:refresh).with(["1145360"])
  end

  it "writes what the watcher returned" do
    expect { perform }.to change { watch.reload.name }.from("Old").to("Hades")
  end

  context "when the provider is unavailable" do
    before do
      allow(Integrations::Steam::NewsWatcher).to receive(:refresh).and_raise(Integrations::Unavailable, "503")
      allow(Rails.logger).to receive(:warn)
    end

    it "logs it and writes nothing" do
      expect { perform }.not_to change { watch.reload.name }
      expect(Rails.logger).to have_received(:warn).with(/refreshing Integrations::Steam::NewsWatcher failed: Integrations::Unavailable: 503/)
    end
  end

  context "when the watcher has a bug" do
    before do
      allow(Integrations::Steam::NewsWatcher).to receive(:refresh).and_raise(KeyError, "boom")
    end

    it "raises" do
      expect { perform }.to raise_error(KeyError)
    end
  end

  context "when nothing is referenced" do
    let(:followed) { [] }

    it "does not call the provider" do
      perform

      expect(Integrations::Steam::NewsWatcher).not_to have_received(:refresh)
    end
  end
end
