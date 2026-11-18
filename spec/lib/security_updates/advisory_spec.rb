# frozen_string_literal: true

require "rails_helper"

RSpec.describe SecurityUpdates::Advisory do
  subject(:advisory) do
    described_class.new(
      package: "rack",
      version: "3.0.0",
      id: "CVE-1",
      title: "Bad thing",
      url: nil,
      fixed_in:
    )
  end

  describe "#fixable?" do
    context "with a patched version" do
      let(:fixed_in) { ["~> 3.1"] }

      it { is_expected.to be_fixable }
    end

    context "without a patched version, so an update cannot help" do
      let(:fixed_in) { [] }

      it { is_expected.not_to be_fixable }
    end
  end
end
