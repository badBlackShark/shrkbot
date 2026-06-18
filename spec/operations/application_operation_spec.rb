require "rails_helper"

RSpec.describe Ops::ApplicationOperation do
  let(:op) do
    Class.new(described_class) do
      def initialize(win:)
        @win = win
      end

      def call
        @win ? ok(42) : failure("nope", "bad")
      end
    end
  end

  context "with success" do
    subject(:result) { op.call(win: true) }

    it "wraps a successful result" do
      expect(result).to have_attributes(success?: true, failure?: false, value: 42, errors: [])
    end
  end

  context "with failure" do
    subject(:result) { op.call(win: false) }

    it "wraps a failure with flattened messages and no value" do
      expect(result).to have_attributes(success?: false, failure?: true, value: nil, errors: %w[nope bad])
    end
  end
end
