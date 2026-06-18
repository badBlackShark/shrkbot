require "rails_helper"

RSpec.describe Plugin do
  describe "#key" do
    it "exposes the stored key as a symbol" do
      expect(create(:plugin, key: "logging").key).to eq(:logging)
    end

    it "is nil when the key is unset" do
      expect(described_class.new.key).to be_nil
    end
  end
end
