# frozen_string_literal: true

require "rails_helper"

RSpec.describe Bot::ErrorReporter do
  describe ".report" do
    subject(:report) { described_class.report(bot:, error:, source: "command /probe") }

    let(:bot) { double("bot") }
    let(:error) { RuntimeError.new("boom") }

    before do
      allow(Rails.error).to receive(:report)
      allow(Bot::OwnerNotifier).to receive(:report)
    end

    it "hands the error to the Rails error reporter as a handled bot error tagged with where it came from" do
      report
      expect(Rails.error).to have_received(:report).with(
        error,
        handled: true,
        severity: :error,
        source: "bot",
        context: {tags: {origin: "command /probe"}}
      )
    end

    it "still DMs the owner" do
      report
      expect(Bot::OwnerNotifier).to have_received(:report).with(bot:, error:, source: "command /probe")
    end
  end
end
