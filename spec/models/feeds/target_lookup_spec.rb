# frozen_string_literal: true

require "rails_helper"

RSpec.describe Feeds::TargetLookup do
  subject(:result) { described_class.call(watcher_class, "440") }

  let(:watcher_class) { class_double(Integrations::Steam::NewsWatcher) }
  let(:target) { Integrations::Target.new(external_id: "440", name: "Team Fortress 2", image_url: nil) }

  before { allow(watcher_class).to receive(:resolve).with("440").and_return(target) }

  it "returns the resolved target and no error" do
    expect(result).to have_attributes(target:, error: nil)
  end

  {
    Integrations::InvalidReference => :invalid_reference,
    Integrations::NotFound => :not_found,
    Integrations::Unavailable => :unavailable,
    Integrations::RateLimited => :unavailable,
    Integrations::Error => :unavailable
  }.each do |error_class, error|
    context "when the watcher raises #{error_class}" do
      before { allow(watcher_class).to receive(:resolve).and_raise(error_class) }

      it "returns #{error.inspect} and no target" do
        expect(result).to have_attributes(target: nil, error:)
      end
    end
  end
end
