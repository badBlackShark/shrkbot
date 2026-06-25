# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ops::ApplicationOperation do
  describe "result helpers" do
    let(:op) do
      Class.new(described_class) do
        receives :win

        def call
          win ? ok(42) : failure("nope", "bad")
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

  describe ".receives" do
    let(:op) do
      Class.new(described_class) do
        receives :required_one, :required_two
        receives :maybe, optional: true
        receives :mode, default: "multi"

        def call
          ok([required_one, required_two, maybe, mode])
        end
      end
    end

    it "exposes every keyword as a reader, applying defaults for the absent ones" do
      expect(op.call(required_one: "a", required_two: "b").value).to eq(["a", "b", nil, "multi"])
    end

    it "accepts overrides for optional and defaulted keywords" do
      expect(op.call(required_one: "a", required_two: "b", maybe: "c", mode: "single").value).to eq(["a", "b", "c", "single"])
    end

    it "raises on a single missing required keyword" do
      expect { op.call(required_two: "b") }.to raise_error(ArgumentError, /missing keyword: :required_one/)
    end

    it "lists every missing required keyword" do
      expect { op.call }.to raise_error(ArgumentError, /missing keywords: :required_one, :required_two/)
    end

    it "raises on a single unknown keyword" do
      expect { op.call(required_one: "a", required_two: "b", bogus: 1) }.to raise_error(ArgumentError, /unknown keyword: :bogus/)
    end

    it "lists every unknown keyword" do
      expect { op.call(required_one: "a", required_two: "b", bogus: 1, junk: 2) }.to raise_error(ArgumentError, /unknown keywords: :bogus, :junk/)
    end

    it "rejects optional:/default: combined with multiple keywords" do
      expect {
        Class.new(described_class) { receives :a, :b, optional: true }
      }.to raise_error(ArgumentError, /single keyword/)
    end
  end

  describe "#call" do
    it "is abstract by default" do
      expect { Class.new(described_class).new.call }.to raise_error(AbstractMethodError, /must implement #call/)
    end
  end

  describe "transaction wrapping" do
    let(:transactional_op) do
      Class.new(described_class) do
        def call
          ok(:done)
        end
      end
    end

    let(:non_transactional_op) do
      Class.new(described_class) do
        self.transactional = false

        def call
          ok(:done)
        end
      end
    end

    it "wraps #execute in a transaction by default" do
      expect(ActiveRecord::Base).to receive(:transaction).and_call_original
      transactional_op.call
    end

    it "skips the transaction when transactional is false" do
      expect(ActiveRecord::Base).not_to receive(:transaction)
      non_transactional_op.call
    end
  end
end
