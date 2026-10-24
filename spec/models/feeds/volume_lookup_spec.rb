# frozen_string_literal: true

require "rails_helper"

RSpec.describe Feeds::VolumeLookup do
  subject(:result) { described_class.call(watcher_class, "440") }

  let(:watcher_class) { class_double(Integrations::Steam::NewsWatcher) }
  let(:volume) { Integrations::Volume.new(counts: {"Integrations::Steam::ArticlePublished" => 3}, sample_size: 20) }

  before { allow(watcher_class).to receive(:volume).with("440").and_return(volume) }

  it "returns the watcher's volume" do
    expect(result).to eq(volume)
  end

  context "when the watcher raises Integrations::Unavailable" do
    before { allow(watcher_class).to receive(:volume).and_raise(Integrations::Unavailable) }

    it { is_expected.to be_nil }
  end
end
