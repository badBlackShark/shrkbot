# frozen_string_literal: true

require "rails_helper"

RSpec.describe TwilightStruggle::GameSequence do
  subject(:advance) { described_class.new(external_id).advance }

  let(:external_id) { "150" }

  def watermark
    BotSetting.get(described_class::SETTING_KEY)
  end

  context "when no watermark is stored yet" do
    it "sets the watermark to the arrived id" do
      expect { advance }.to change { watermark }.from(nil).to("150")
    end

    it "returns no candidates" do
      expect(advance).to eq([])
    end
  end

  context "when the arrival is above the watermark" do
    before { BotSetting.set(described_class::SETTING_KEY, "145") }

    it "returns the ids between the watermark and the arrival" do
      expect(advance).to eq([146, 147, 148, 149])
    end

    it "advances the watermark to the arrival" do
      expect { advance }.to change { watermark }.from("145").to("150")
    end
  end

  context "when the arrival equals the watermark" do
    before { BotSetting.set(described_class::SETTING_KEY, "150") }

    it "returns no candidates" do
      expect(advance).to eq([])
    end

    it "leaves the watermark unchanged" do
      expect { advance }.not_to change { watermark }
    end
  end

  context "when the arrival is below the watermark" do
    before { BotSetting.set(described_class::SETTING_KEY, "200") }

    it "returns no candidates" do
      expect(advance).to eq([])
    end

    it "leaves the watermark unchanged" do
      expect { advance }.not_to change { watermark }
    end
  end

  context "when the arrival is exactly one above the watermark" do
    before { BotSetting.set(described_class::SETTING_KEY, "149") }

    it "advances the watermark" do
      expect { advance }.to change { watermark }.from("149").to("150")
    end

    it "returns no candidates" do
      expect(advance).to eq([])
    end
  end
end
