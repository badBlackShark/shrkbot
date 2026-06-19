require "rails_helper"

RSpec.describe Ops::ApplicationOperation do
  describe "result helpers" do
    let(:op) do
      Class.new(described_class) do
        receives :win

        def execute
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
        receives :required_one, optional: [:maybe], default: {mode: "multi"}

        def execute
          ok([required_one, maybe, mode])
        end
      end
    end

    it "exposes the keywords as readers" do
      expect(op.call(required_one: "x").value).to eq(["x", nil, "multi"])
    end

    it "applies defaults and accepts overrides" do
      expect(op.call(required_one: "x", maybe: "y", mode: "single").value).to eq(["x", "y", "single"])
    end

    it "raises on a missing required keyword" do
      expect { op.call(maybe: "y") }.to raise_error(ArgumentError, /missing keyword: :required_one/)
    end

    it "lists every missing required keyword" do
      two = Class.new(described_class) do
        receives :a, :b

        def execute
          ok
        end
      end
      expect { two.call }.to raise_error(ArgumentError, /missing keywords: :a, :b/)
    end

    it "raises on an unknown keyword" do
      expect { op.call(required_one: "x", bogus: 1) }.to raise_error(ArgumentError, /unknown keyword: :bogus/)
    end

    it "lists every unknown keyword" do
      expect { op.call(required_one: "x", bogus: 1, junk: 2) }.to raise_error(ArgumentError, /unknown keywords: :bogus, :junk/)
    end
  end

  describe "#execute" do
    it "is abstract by default" do
      expect { Class.new(described_class).new.execute }.to raise_error(AbstractMethodError, /must implement #execute/)
    end
  end

  describe "transaction wrapping" do
    let(:transactional_op) do
      Class.new(described_class) do
        def execute
          ok(:done)
        end
      end
    end

    let(:non_transactional_op) do
      Class.new(described_class) do
        self.transactional = false

        def execute
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
