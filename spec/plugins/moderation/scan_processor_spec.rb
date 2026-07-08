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

  let(:client_double) { double("client") }
  let(:verdict) { Moderation::Verdict.new(action: :allow, risk: 0.0, reasons: []) }
  let(:http) { double("http") }
  let(:response) { double("response", code: "200", body: "bytes") }

  before do
    allow(Net::HTTP).to receive(:start) { |*_args, &block| block.call(http) }
    allow(http).to receive(:get).and_return(response)
    allow(Moderation::Ocr::Client).to receive(:new).and_return(client_double)
    allow(client_double).to receive(:scan).with("bytes").and_return({"text" => "won usdt bonus"})
    allow(Moderation::Classifier).to receive(:call).and_return(verdict)
    allow(Moderation::VerdictExecutor).to receive(:call)
  end

  context "on the happy path" do
    it "classifies the OCR text and hands the verdict to the executor" do
      process

      expect(Moderation::Classifier).to have_received(:call).with(
        ocr_text: "won usdt bonus",
        hash_state: :none,
        signals:,
        settings:
      )
      expect(Moderation::VerdictExecutor).to have_received(:call).with(verdict:, context:)
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

  context "when the attachment download returns a non-success status" do
    let(:response) { double("response", code: "404", body: "") }

    it "rescues without raising and does not run the executor" do
      expect { process }.not_to raise_error
      expect(Moderation::VerdictExecutor).not_to have_received(:call)
    end
  end

  context "when the attachment download connection fails" do
    before do
      allow(Net::HTTP).to receive(:start).and_raise(SocketError, "no dns")
    end

    it "rescues without raising and does not run the executor" do
      expect { process }.not_to raise_error
      expect(Moderation::VerdictExecutor).not_to have_received(:call)
    end
  end
end
