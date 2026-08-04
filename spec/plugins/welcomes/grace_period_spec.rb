# frozen_string_literal: true

require "rails_helper"

RSpec.describe Welcomes::GracePeriod do
  subject(:after) { described_class.after(&block) }

  before { allow(described_class).to receive(:sleep) }

  context "with a block that succeeds" do
    let(:ran) { [] }
    let(:block) { -> { ran << true } }

    it "runs the block" do
      after.join

      expect(ran).to eq([true])
    end
  end

  context "with a block that raises" do
    let(:block) { -> { raise "boom" } }

    before { allow(Rails.logger).to receive(:error) }

    it "logs the error instead of raising out" do
      after.join

      expect(Rails.logger).to have_received(:error).with(/GracePeriod.*boom/)
    end
  end
end
