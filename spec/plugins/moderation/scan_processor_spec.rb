# frozen_string_literal: true

require "rails_helper"

RSpec.describe Moderation::ScanProcessor do
  subject(:process) { described_class.call(context) }

  let(:signals) { {account_age_days: 2, has_link: true, has_role: false} }
  let(:settings) { double("settings") }
  let(:context) do
    Moderation::ScanContext.new(
      bot: double("bot"),
      server: double("server", id: 1),
      member: double("member", id: 2),
      channel_id: 3,
      message_id: 4,
      attachment_url: "https://cdn/x.png",
      signals:,
      settings:
    )
  end

  let(:hex) { "deadbeefdeadbeef" }
  let(:state) { :none }
  let(:client_double) { double("client") }
  let(:verdict) { Moderation::Verdict.new(action: :allow, risk: 0.0, reasons: []) }

  before do
    allow(Moderation::ImageDownload).to receive(:call).and_return("bytes")
    allow(Moderation::Ocr::Client).to receive(:new).and_return(client_double)
    allow(client_double).to receive(:phash).with("bytes").and_return(hex)
    allow(client_double).to receive(:scan).with("bytes").and_return({"text" => "won usdt"})
    allow(Moderation::PhashIndex).to receive(:lookup).and_return(state)
    allow(Ops::Moderation::Phashes::MarkSeen).to receive(:call)
    allow(Moderation::Classifier).to receive(:call).and_return(verdict)
    allow(Moderation::VerdictExecutor).to receive(:call)
  end

  context "when the phash is unknown (state :none)" do
    let(:state) { :none }

    it "runs the OCR scan and classifies with the unknown hash state" do
      process

      expect(client_double).to have_received(:scan).with("bytes")
      expect(Moderation::Classifier).to have_received(:call).with(
        ocr_text: "won usdt",
        hash_state: :none,
        signals:,
        settings:
      )
      expect(Moderation::VerdictExecutor).to have_received(:call).with(verdict:, context:, phash: hex, image_bytes: "bytes")
    end

    it "does not touch last_seen" do
      process
      expect(Ops::Moderation::Phashes::MarkSeen).not_to have_received(:call)
    end
  end

  context "when the phash is this guild's confirmed scam (state :own_confirmed)" do
    let(:state) { :own_confirmed }

    it "skips the OCR scan and classifies with empty text" do
      process

      expect(client_double).not_to have_received(:scan)
      expect(Moderation::Classifier).to have_received(:call).with(
        ocr_text: "",
        hash_state: :own_confirmed,
        signals:,
        settings:
      )
    end

    it "touches last_seen with the hex and runs the executor" do
      process

      expect(Ops::Moderation::Phashes::MarkSeen).to have_received(:call).with(phash_hex: hex)
      expect(Moderation::VerdictExecutor).to have_received(:call).with(verdict:, context:, phash: hex, image_bytes: "bytes")
    end
  end

  context "when the phash is another guild's confirmed scam (state :foreign_confirmed)" do
    let(:state) { :foreign_confirmed }

    it "still runs the OCR scan and classifies with the foreign hash state" do
      process

      expect(client_double).to have_received(:scan).with("bytes")
      expect(Moderation::Classifier).to have_received(:call).with(
        ocr_text: "won usdt",
        hash_state: :foreign_confirmed,
        signals:,
        settings:
      )
    end

    it "touches last_seen" do
      process
      expect(Ops::Moderation::Phashes::MarkSeen).to have_received(:call).with(phash_hex: hex)
    end
  end

  context "when the phash was dismissed here (state :own_dismissed)" do
    let(:state) { :own_dismissed }

    it "touches last_seen then short-circuits" do
      process

      expect(Ops::Moderation::Phashes::MarkSeen).to have_received(:call).with(phash_hex: hex)
      expect(Moderation::Classifier).not_to have_received(:call)
      expect(Moderation::VerdictExecutor).not_to have_received(:call)
    end
  end

  context "when the OCR scan raises an Ocr::Error" do
    before do
      allow(client_double).to receive(:scan).and_raise(Moderation::Ocr::Error, "boom")
    end

    it "rescues without raising and does not run the executor" do
      expect { process }.not_to raise_error
      expect(Moderation::VerdictExecutor).not_to have_received(:call)
    end
  end

  context "when the phash call raises an Ocr::Error" do
    before do
      allow(client_double).to receive(:phash).and_raise(Moderation::Ocr::Error, "boom")
    end

    it "rescues without raising and does not run the executor" do
      expect { process }.not_to raise_error
      expect(Moderation::VerdictExecutor).not_to have_received(:call)
    end
  end

  context "when the attachment download returns a non-success status" do
    before do
      allow(Moderation::ImageDownload).to receive(:call).and_raise(Moderation::Ocr::Error, "attachment download failed: 404")
    end

    it "rescues without raising and does not run the executor" do
      expect { process }.not_to raise_error
      expect(Moderation::VerdictExecutor).not_to have_received(:call)
    end
  end

  context "when the attachment download connection fails" do
    before do
      allow(Moderation::ImageDownload).to receive(:call).and_raise(Moderation::Ocr::Error, "no dns")
    end

    it "rescues without raising and does not run the executor" do
      expect { process }.not_to raise_error
      expect(Moderation::VerdictExecutor).not_to have_received(:call)
    end
  end
end
