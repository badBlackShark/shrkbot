# frozen_string_literal: true

require "rails_helper"

RSpec.describe Integrations::Language do
  describe ".detect" do
    subject(:language) { described_class.detect(text) }

    context "with a German paragraph" do
      let(:text) { "Das neue Update ist jetzt verfügbar. Es behebt mehrere Abstürze beim Start des Spiels und verbessert die Leistung auf schwächeren Rechnern." }

      it { is_expected.to eq("de") }
    end

    context "with an English paragraph" do
      let(:text) { "The new update is now available. It fixes several crashes on launch and improves performance on lower-end machines." }

      it { is_expected.to eq("en") }
    end

    context "with one line repeated in four languages" do
      let(:text) { "Nuevo parche disponible. New patch available. Neuer Patch verfügbar. Nouveau patch disponible." }

      it { is_expected.to be_nil }
    end

    context "with a text too short to judge" do
      let(:text) { "The new update is now available" }

      it { is_expected.to be_nil }
    end

    context "with only images and bare URLs" do
      let(:text) do
        "![banner](https://cdn.example.com/images/banner.png) https://store.steampowered.com/app/440/Team_Fortress_2/ ![logo](https://cdn.example.com/images/logo.png)"
      end

      it { is_expected.to be_nil }
    end
  end

  describe "CODES" do
    it "mirrors the model's labels" do
      expect(described_class::CODES.sort).to eq(described_class.model.labels.sort)
    end
  end

  describe "MODEL_PATH" do
    it "is the model file the codes were taken from" do
      expect(Digest::SHA256.file(described_class::MODEL_PATH).hexdigest).to eq("8f3472cfe8738a7b6099e8e999c3cbfae0dcd15696aac7d7738a8039db603e83")
    end
  end
end
