# frozen_string_literal: true

require "rails_helper"

RSpec.describe Feeds::VolumeLookup do
  subject(:result) { described_class.call(watcher_class, "440") }

  let(:watcher_class) { class_double(Integrations::Steam::NewsWatcher) }
  before { allow(watcher_class).to receive(:volume).with("440").and_raise(Integrations::RateLimited) }

  it "returns nil for any integration error" do
    expect(result).to be_nil
  end
end
