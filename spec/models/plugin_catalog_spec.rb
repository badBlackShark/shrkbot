require "rails_helper"

RSpec.describe PluginCatalog do
  describe ".find" do
    it "looks a definition up by key" do
      expect(described_class.find(:logging).name).to eq("Logging")
    end

    it "is nil for an unknown key" do
      expect(described_class.find(:nope)).to be_nil
    end
  end

  describe ".channel_backed" do
    it "returns only the channel-backed definitions" do
      expect(described_class.channel_backed).to all(be_channel_backed)
    end
  end

  describe PluginCatalog::Definition do
    def definition(channel_setting:)
      described_class.new(key: :x, name: "X", description: "", default_enabled: false, channel_setting:)
    end

    context "when not channel-backed" do
      it "has no prerequisites" do
        expect(definition(channel_setting: nil).prerequisites_met?(Object.new)).to be(true)
      end
    end

    context "when channel-backed" do
      subject(:check) { definition(channel_setting: :logging_setting).prerequisites_met?(config) }

      context "without a channel" do
        let(:config) { double(logging_setting: nil) }

        it { is_expected.to be(false) }
      end

      context "with a channel" do
        let(:config) { double(logging_setting: double(channel_id: 5)) }

        it { is_expected.to be(true) }
      end
    end
  end
end
