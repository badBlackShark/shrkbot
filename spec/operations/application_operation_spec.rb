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

  it "wraps a successful result" do
    result = op.call(win: true)
    expect(result).to have_attributes(success?: true, failure?: false, value: 42, errors: [])
  end

  it "wraps a failure with flattened messages and no value" do
    result = op.call(win: false)
    expect(result).to have_attributes(success?: false, failure?: true, value: nil, errors: %w[nope bad])
  end
end
