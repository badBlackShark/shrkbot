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

  describe ".by_external_id" do
    subject(:result) { described_class.by_external_id(watcher_class, "440") }

    before { allow(watcher_class).to receive(:refresh).with(["440"]).and_return(refreshed) }

    context "when the provider knows the id" do
      let(:refreshed) { [target] }

      it "returns the target and no error" do
        expect(result).to have_attributes(target:, error: nil)
      end
    end

    context "when the provider returns nothing for the id" do
      let(:refreshed) { [] }

      it "returns :not_found and no target" do
        expect(result).to have_attributes(target: nil, error: :not_found)
      end
    end

    context "when the provider is down" do
      let(:refreshed) { [] }

      before { allow(watcher_class).to receive(:refresh).and_raise(Integrations::Unavailable) }

      it "returns :unavailable and no target" do
        expect(result).to have_attributes(target: nil, error: :unavailable)
      end
    end
  end
end
